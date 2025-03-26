class InstagramPost < ApplicationRecord
  belongs_to :topic
  validates :instagram_id, presence: true, uniqueness: true
  
  require 'open-uri'
  require 'net/http'
  require 'uri'
  require 'socksify'
  require 'fileutils'
  
  # 处理标签列表
  def hashtags
    if self[:hashtags].present?
      YAML.load(self[:hashtags])
    else
      []
    end
  end
  
  def hashtags=(tags)
    self[:hashtags] = tags.to_yaml if tags.present?
  end
  
  def self.download_image(url)
    return nil unless url.present?
    
    begin
      # 图片保存目录
      storage_dir = Rails.root.join('public', 'images')
      FileUtils.mkdir_p(storage_dir) unless Dir.exist?(storage_dir)
      
      # 生成唯一的文件名，并统一使用 .png 扩展名
      file_name = "#{SecureRandom.uuid}.png"
      file_path = storage_dir.join(file_name)
      
      # 从环境变量获取代理设置
      proxy_host = ENV['PROXY_HOST'] 
      proxy_port = ENV['PROXY_PORT'] 
      
      # 设置代理
      TCPSocket.socks_server = proxy_host
      TCPSocket.socks_port = proxy_port.to_i
      
      # 解析URL
      uri = URI.parse(url)
      
      # 创建HTTP连接
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      # 创建请求
      request = Net::HTTP::Get.new(uri.request_uri)
      request["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36"
      request["Referer"] = "https://www.instagram.com/"
      request["Accept-Language"] = "en-US,en;q=0.5"
      request["Connection"] = "keep-alive"
      
      # 发送请求并获取响应
      response = http.request(request)
      
      if response.code == "200"
        # 保存图片
        File.open(file_path, "wb") { |file| file.write(response.body) }
        Rails.logger.info("图片下载成功: #{file_name}")
        # 返回可访问的URL路径
        "/images/#{file_name}"
      else
        Rails.logger.error("下载失败，HTTP 状态码: #{response.code}")
        nil
      end
    rescue => e
      Rails.logger.error("下载图片失败: #{e.message}")
      nil
    end
  end
  
  def self.refresh_for_topic(topic, cancellation_key = nil)
    # 检查是否已请求取消
    def self.check_cancellation(cancellation_key)
      return false unless cancellation_key
      Rails.cache.exist?(cancellation_key)
    end
    
    # 检查一次取消状态
    if check_cancellation(cancellation_key)
      Rails.logger.info("用户在开始抓取前取消了数据获取请求")
      return { cancelled: true, success: false, new_posts: [] }
    end
    
    # 初始化抓取服务，传递取消键
    scraper = InstagramScraperService.new(cancellation_key)
    
    # 获取Instagram数据
    result = scraper.fetch_posts(topic.name)
    
    # 检查结果是否已标记为取消
    if result[:cancelled]
      Rails.logger.info("数据抓取过程已被用户取消")
      return { cancelled: true, success: false, new_posts: [] }
    end
    
    # 检查是否请求取消
    if check_cancellation(cancellation_key)
      Rails.logger.info("用户在获取数据后取消了请求")
      return { cancelled: true, success: false, new_posts: [] }
    end
    
    # 检查是否成功获取数据
    if result.nil? || result[:posts].nil? || result[:posts].empty?
      error_message = result.nil? ? "数据获取失败" : (result[:error] || "未找到帖子")
      Rails.logger.error("Instagram数据获取失败: #{error_message}")
      return { success: false, error: error_message }
    end
    
    begin
      # 获取现有的帖子ID列表
      existing_post_ids = topic.instagram_posts.pluck(:instagram_id)
      new_posts = []
      
      result[:posts].each do |post_data|
        # 每次处理一个帖子前检查是否请求取消
        if check_cancellation(cancellation_key)
          Rails.logger.info("用户在处理帖子过程中取消了请求")
          return { cancelled: true, success: false, new_posts: new_posts }
        end
        
        # 跳过已存在的帖子
        next if existing_post_ids.include?(post_data[:instagram_id])
        
        # 下载图片到本地
        local_image_url = download_image(post_data[:image_url])
        Rails.logger.info("图片已下载到: #{local_image_url || '下载失败'}")
        
        # 尝试解析 posted_at 文本为时间对象用于排序
        order_time = nil
        begin
          if post_data[:order_time].present?
            # 尝试解析常见的日期格式
            order_time = Time.parse(post_data[:order_time])
          end
        rescue
          # 如果解析失败，使用当前时间
          order_time = Time.current
        end
        
        # 创建新帖子
        post = topic.instagram_posts.new(
          instagram_id: post_data[:instagram_id],
          username: post_data[:username],
          caption: post_data[:caption],
          image_url: local_image_url || post_data[:image_url],
          posted_at: post_data[:posted_at],
          likes_count: post_data[:likes_count],
          post_url: post_data[:post_url],
          hashtags: post_data[:hashtags],
          order_time: order_time || Time.current  # 设置排序时间
        )
        
        post.save!
        new_posts << post
      end
      
      # 再次检查是否请求取消
      if check_cancellation(cancellation_key)
        Rails.logger.info("用户在数据处理完成后取消了请求")
        return { cancelled: true, success: false, new_posts: new_posts }
      end
      
      # 广播更新 (如果使用ActionCable)
      ActionCable.server.broadcast("topic_#{topic.id}", { posts: new_posts }) if defined?(ActionCable)
      Rails.logger.info("抓取结束，清理资源")
      # 无论是否有新帖子，都返回成功状态
      { success: true, new_posts: new_posts }
    rescue => e
      Rails.logger.error("处理Instagram数据时出错: #{e.message}")
      { success: false, error: "更新帖子时出错: #{e.message}" }
    end
  end

end