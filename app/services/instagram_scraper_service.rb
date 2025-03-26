require 'nokogiri'
require 'json'
require 'selenium-webdriver'
require 'socksify'
require 'net/http'
require 'webdrivers'
require 'httparty'
require 'dotenv'
require 'fileutils'
require 'securerandom'

class InstagramScraperService
  def initialize(cancellation_key = nil)
    # 设置取消标记键
    @cancellation_key = cancellation_key
    @cancelled = false
    @cancellation_thread = nil
    
    # 如果存在旧的取消标记，先清除它
    if @cancellation_key && Rails.cache.exist?(@cancellation_key)
      Rails.cache.delete(@cancellation_key)
    end
    
    @config = {
      'credentials' => {
        'username' => ENV['INSTAGRAM_USERNAME'],
        'password' => ENV['INSTAGRAM_PASSWORD']
      },
      'headless' => ENV['HEADLESS_BROWSER'] == 'true',
      'max_posts' => (ENV['MAX_POSTS'] || 10).to_i
    }
    
    @login_attempts = 0
    @max_login_attempts = 3
    
    start_cancellation_monitor if @cancellation_key
    Rails.logger.info("启动取消监控线程")
    # 获取共享的WebDriver实例
    setup_selenium
  end

  def setup_selenium
    begin
      # 首先清理之前的实例和进程
      # cleanup_driver
      # kill_edge_driver_processes
      
      Rails.logger.info("初始化Edge浏览器...")
      
      # 创建临时用户数据目录
      user_data_dir = create_temp_user_data_dir
      Rails.logger.info("创建临时用户数据目录: #{user_data_dir}")
      
      options = Selenium::WebDriver::Edge::Options.new

      # 设置浏览器无头模式
      if @config['headless']
        options.add_argument('--headless=new')
      end
      
      # 使用临时用户数据目录
      options.add_argument("--user-data-dir=#{user_data_dir}")
      options.add_argument("--profile-directory=Profile")
      
      # 基本参数设置
      options.add_argument('--disable-gpu')
      options.add_argument('--no-sandbox')
      options.add_argument('--disable-dev-shm-usage')
      options.add_argument('--window-size=1920,1080')
      options.add_argument('--disable-extensions')
      options.add_argument('--disable-popup-blocking')
      options.add_argument('--disable-infobars')
      
      # 添加一个标准的用户代理
      options.add_argument("--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0")
      
      # 禁用自动化特征
      options.add_argument('--disable-blink-features=AutomationControlled')
      
      # 重试次数
      retry_count = 0
      max_retries = 1
      
      # 确保webdriver版本与浏览器版本匹配
      Webdrivers::Edgedriver.update
      begin
        # 使用临时用户数据目录创建服务实例
        service_args = ["--log-path=#{Rails.root.join('log', 'edgedriver.log')}"]
        service = Selenium::WebDriver::Edge::Service.new(args: service_args)


        @driver = Selenium::WebDriver.for(:edge, options: options, service: service)
        # @driver = Selenium::WebDriver.for(:edge, options: options)
        # Rails.logger.info("调试日志2")
        # 隐式等待时间在查找元素时，如果元素没有立即出现，WebDriver 会在指定的时间内不断尝试查找该元素，直到元素出现或者超时
        @driver.manage.timeouts.implicit_wait = 10
        # 页面加载超时时间，如果页面在指定时间内没有加载完成，WebDriver 会抛出超时异常
        @driver.manage.timeouts.page_load = 30
        # 脚本执行超时时间，如果脚本在指定时间内没有执行完成，WebDriver 会抛出超时异常
        @driver.manage.timeouts.script_timeout = 10
        # 禁用WebDriver标识
        begin
          @driver.execute_script('Object.defineProperty(navigator, "webdriver", {get: () => false});')
        rescue => e
          Rails.logger.warn("无法禁用WebDriver标识: #{e.message}")
        end
        
        
        Rails.logger.info("Edge WebDriver初始化成功，使用临时目录: #{user_data_dir}")
      rescue EOFError => e
        Rails.logger.error("EOFError: #{e.message}")
        retry_count += 1
        
        if retry_count <= max_retries
          Rails.logger.info("尝试重新初始化WebDriver (#{retry_count}/#{max_retries})...")
          # 清理资源
          kill_edge_driver_processes
          sleep(5)  # 等待更长时间
          # 创建新的临时目录
          user_data_dir = create_temp_user_data_dir
          retry
        else
          Rails.logger.error("WebDriver初始化失败，已达到最大重试次数")
          @driver = nil
        end
      rescue => e
        Rails.logger.error("WebDriver初始化失败: #{e.message}")
        @driver = nil
      end
    end
  end
  
  # 创建临时用户数据目录
  def create_temp_user_data_dir
    timestamp = Time.now.to_i
    random_suffix = SecureRandom.hex(4)
    dir_name = "edge_user_data_#{timestamp}_#{random_suffix}"
    temp_dir = File.join(Dir.tmpdir, dir_name)
    
    # 创建目录
    FileUtils.mkdir_p(temp_dir)
    temp_dir
  end
  
  def kill_edge_driver_processes
    begin
      Rails.logger.info("尝试杀死残留的WebDriver进程...")
      
      if Gem.win_platform?
        # Windows平台
        system("taskkill /F /IM msedgedriver.exe /T")
        # system("taskkill /F /IM msedge.exe /T")
        sleep(2)  # 增加等待时间
      else
        # Linux/Mac平台
        system("pkill -f 'msedgedriver'")
        sleep(2)
      end
      
      Rails.logger.info("WebDriver进程清理完成")
    rescue => e
      Rails.logger.error("清理WebDriver进程失败: #{e.message}")
    end
  end
  
  # 清理共享驱动实例
  def cleanup_driver  
    if @driver
      Rails.logger.info("正在清理WebDriver实例...")
      begin
        @driver.quit
      rescue => e
        Rails.logger.error("关闭WebDriver实例时出错: #{e.message}")
      end
      @driver = nil
    end
    kill_edge_driver_processes
    cleanup_temp_dirs
  end
  
  # 清理临时目录
  def cleanup_temp_dirs
    begin
      pattern = File.join(Dir.tmpdir, "edge_user_data_*")
      dirs = Dir.glob(pattern)
      
      # 删除创建超过1小时的临时目录
      dirs.each do |dir|
        if File.directory?(dir)
          # 从目录名提取时间戳
          timestamp_match = dir.match(/edge_user_data_(\d+)/)
          if timestamp_match && timestamp_match[1]
            timestamp = timestamp_match[1].to_i
            if Time.now.to_i - timestamp > 3600 # 1小时
              Rails.logger.info("删除旧的临时目录: #{dir}")
              FileUtils.remove_dir(dir, true) rescue nil
            end
          end
        end
      end
    rescue => e
      Rails.logger.error("清理临时目录时出错: #{e.message}")
    end
  end

  def login_to_instagram
    return if logged_in?
    return if @login_attempts >= @max_login_attempts

    begin
      @login_attempts += 1
      Rails.logger.info("尝试登录Instagram ( #{@login_attempts}/#{@max_login_attempts})")

      credentials = @config['credentials']
      username = credentials['username']
      password = credentials['password']

      unless username && password
        Rails.logger.error("未配置账号密码！")
        return false
      end

      # 访问登录页面
      @driver.navigate.to('https://www.instagram.com/accounts/login/')
      sleep(1)
      
      # 查找用户名输入框
      username_field = find_element_safely(:css, 'input[name="username"]') || 
                      find_element_safely(:css, 'input[aria-label="手机号、 账号或邮箱"]') ||
                      find_element_safely(:css, 'input[aria-label="Phone number, username, or email"]')
      
      if username_field
        username_field.clear
        username_field.send_keys(username)
        # sleep(1)
      else
        Rails.logger.error("无法找到用户名输入框")
        # return false
      end
      
      # 查找密码输入框
      password_field = find_element_safely(:css, 'input[name="password"]') ||
                      find_element_safely(:css, 'input[aria-label="密码"]') ||
                      find_element_safely(:css, 'input[aria-label="Password"]')
      
      if password_field
        password_field.clear
        password_field.send_keys(password)
        # sleep(1)
      else
        Rails.logger.error("无法找到密码输入框")
        # return false
      end
      
      # 查找登录按钮
      login_button = find_element_safely(:css, 'button[type="submit"]')
      
      if login_button
        login_button.click
        sleep(5)
      else
        Rails.logger.error("无法找到登录按钮")
        return false
      end
      
      # 检查登录状态
      if logged_in?
        Rails.logger.info("登录成功")
        return true
      else
        Rails.logger.error("登录失败，尝试重试...")
        sleep(2)  # 等待一下再重试
        return login_to_instagram  # 递归重试
      end
    rescue => e
      Rails.logger.error("登录Instagram失败: #{e.message}")
      if @login_attempts < @max_login_attempts
        sleep(2)  # 等待一下再重试
        return login_to_instagram  # 递归重试
      end
      return false
    end
  end

  def find_element_safely(by, selector)
    begin
      @driver.find_element(by, selector)
    rescue Selenium::WebDriver::Error::NoSuchElementError
      nil
    end
  end

  def logged_in?
    !@driver.current_url.include?("accounts/login")
  end

  def should_cancel?
    return false unless @cancellation_key
    if Rails.cache.exist?(@cancellation_key)
      Rails.logger.info("取消状态检查: true")
      cleanup
      true
    else
      false
    end
  end

  def get_tag_media_nodes(tag)
    url = "https://www.instagram.com/explore/tags/#{tag}/"

    begin
      Rails.logger.info("访问Instagram标签页: #{url}")
      

      return [] if should_cancel?
      
      # 直接访问标签页
      @driver.navigate.to(url)
      return [] if should_cancel?

      # 检查是否需要登录
      if @driver.current_url.include?("accounts/login")
        login_to_instagram
        sleep(3)
        # 登录成功后重新访问标签页
        @driver.navigate.to(url)
        sleep(4)
        return [] if should_cancel?
      end
      
      # 获取页面源代码
      html = @driver.page_source
      doc = Nokogiri::HTML(html)
      return [] if should_cancel?
      
      begin
        load_more = find_element_safely(:xpath, "//span[contains(text(), '加载更多')]/ancestor::button")
        if load_more
          return [] if should_cancel?
          load_more.click
          return [] if should_cancel?
          html = @driver.page_source
          doc = Nokogiri::HTML(html)
        end
      rescue => e
        Rails.logger.info("未找到加载更多按钮或点击失败: #{e.message}")
      end

      return [] if should_cancel?
      extract_data_from_html(doc)
    rescue => e
      Rails.logger.error("获取标签数据失败: #{e.message}")
      nil
    end
  end

  def extract_username_and_text(html)
    doc = Nokogiri::HTML(html)
    # 获取用户名
    username_span = doc.css('a[href^="/"][href$="/"] div div span._ap3a._aaco._aacw._aacx._aad7._aade').first
    username = username_span.text.strip
     # 发布时间
    time_element=doc.css('time.x1p4m5qa').first
    if time_element
      datetime = time_element['datetime']
      time_text = time_element.text
    end
    # 获取点赞数
    like_span = doc.css('a[href*="/liked_by/"] span.html-span')
    like_count=like_span.text.strip
    # 获取文案
    text = ""
    doc.css('span.x193iq5w.xeuugli.x1fj9vlw.x13faqbe.x1vvkbs.xt0psk2.x1i0vuye.xvs91rp.xo1l8bm.x5n08af.x10wh9bi.x1wdrske.x8viiok.x18hxmgj').each do |span_tag|
      text = span_tag.text.strip # 获取文案并去掉两边的空格
    end
    [username, text,like_count,time_text,datetime]
  end

  def extract_data_from_html(html)
    posts = []
    links = html.css('a').select { |a| a['href']&.include?('/p/') && (a.css('img').any? || a.css('div:has(img)').any?) }
    Rails.logger.info("找到#{links.length}个含图片的帖子链接")
    links.each do |link|
      return posts if should_cancel?
      
      begin
        post_url = link['href']
        instagram_id = post_url.split('/p/').last.split('/').first
        new_post_url = "https://www.instagram.com" + post_url

        begin
          Rails.logger.info("访问帖子详情页: #{new_post_url}")
          @driver.navigate.to(new_post_url)
          sleep(1)
          return posts if should_cancel?  #取消状态检查点
          detail_html = @driver.page_source
          username, caption, likes_count, posted_at, order_time = extract_username_and_text(detail_html)
        rescue => e
          Rails.logger.error("访问帖子详情页失败: #{e.message}")
          username = "未知用户"
          caption = ""
          likes_count = "0"
          posted_at = ""
          order_time = Time.now.strftime("%Y-%m-%d %H:%M")
        end

          img = link.css('img').first
          image_url = img&.attr('src')
          
          if !image_url && img
            image_url = img['srcset']&.split(' ')&.first # 从srcset中提取第一个URL
          end
          Rails.logger.info("从详情页提取到用户名: #{username}, 文案: #{caption&.slice(0, 30)}...,
           点赞数: #{likes_count}, 发布时间: #{posted_at},图片url: #{image_url}")
          
          # 如果找不到img标签，尝试查找背景图片
          if !image_url
            div_with_style = link.css('div[style*="background-image"]').first
            if div_with_style
              style = div_with_style['style']
              url_match = style.match(/background-image:\s*url\(['"]?([^'"\)]+)/)
              image_url = url_match[1] if url_match
            end
          end
          
          # 确保图片URL是有效的
          if image_url.present?
            begin
              uri = URI.parse(image_url)
              unless uri.scheme.present?
                image_url = "https:#{image_url}"
              end
            rescue URI::InvalidURIError => e
              Rails.logger.error("无效的图片URL: #{image_url}, 错误: #{e.message}")
              image_url = nil
            end
          end
          
          # 提取标签
          hashtags = []
          if caption
            hashtags = caption.scan(/#(\w+)/).flatten.first(10)  # 只取前10个标签
          end
          
          # 确保帖子URL是完整URL
          if post_url && !post_url.start_with?('http')
            post_url = "https://www.instagram.com#{post_url}"
          end
          
          Rails.logger.info("从链接提取到帖子: #{instagram_id}, 用户名: #{username}, 图片: #{image_url&.slice(0, 30)}...")
          
          posts << {
            instagram_id: instagram_id,
            username: username,
            caption: caption,
            image_url: image_url,
            posted_at: posted_at || "",
            order_time: order_time,
            likes_count: likes_count.to_i,
            post_url: post_url,
            hashtags: hashtags
          }

        # 检查是否达到最大帖子数量限制
        break if posts.size >= @config['max_posts']
      rescue => e
        Rails.logger.error("处理帖子数据失败: #{e.message}")
        next
      end
    end
    Rails.logger.info("总共提取到#{posts.size}个帖子")
    posts
  end

  def fetch_posts(topic_name)
    begin
      @hashtag = URI.encode_uri_component(topic_name.downcase.gsub(/\s+/, ''))
      
      unless @driver
        return { error: "Browser initialization failed", posts: [] }
      end
      
      posts = get_tag_media_nodes(@hashtag) || []
      
      if posts.empty?
        return { error: "No posts found", posts: [] }
      end
      
      # 限制数量
      posts = posts.first(@config['max_posts'])
      
      { success: true, posts: posts }
    rescue => e
      { error: e.message, posts: [] }
    ensure
      cleanup
    end
  end

  # 清理资源
  def cleanup
    Rails.logger.info("开始清理资源...")
    cleanup_driver
    # 清理取消状态
    if @cancellation_key
      Rails.logger.info("清理取消状态，key: #{@cancellation_key}")
      Rails.cache.delete(@cancellation_key)
      @cancelled = false
    end

    # 停止取消监控线程
    if @cancellation_thread && @cancellation_thread.alive?
      Rails.logger.info("停止取消监控线程...")
      @cancellation_thread.exit
      @cancellation_thread = nil
    end
    Rails.logger.info("资源清理完成")
  end

  def start_cancellation_monitor
    @cancellation_thread = Thread.new do
      begin
        while !@cancelled
          if Rails.cache.exist?(@cancellation_key)
            Rails.logger.info("取消监控线程检测到取消请求")
            @cancelled = true
            cleanup
            break
          end
          sleep(0.1)
        end
        Rails.logger.info("取消监控线程已结束")
      rescue => e
        Rails.logger.error("取消监控线程异常: #{e.message}")
      end
    end
  end
end