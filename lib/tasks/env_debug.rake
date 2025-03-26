namespace :env do
  desc "显示环境变量加载状态"
  task debug: :environment do
    puts "==== 环境诊断工具 ===="
    puts "当前目录: #{Dir.pwd}"
    
    env_file = Rails.root.join('.env')
    puts ".env 文件路径: #{env_file}"
    puts ".env 文件存在: #{File.exist?(env_file)}"
    
    if File.exist?(env_file)
      puts ".env 文件大小: #{File.size(env_file)} 字节"
      puts ".env 文件权限: #{File.stat(env_file).mode.to_s(8)}"
      puts ".env 文件内容预览:"
      puts "--------------------"
      puts File.readlines(env_file).first(5).join
      puts "--------------------"
    end
    
    puts "\n环境变量值:"
    [
      'INSTAGRAM_USERNAME', 
      'INSTAGRAM_PASSWORD', 
      'PROXY_ENABLED', 
      'PROXY_TYPE', 
      'PROXY_HOST', 
      'PROXY_PORT',
      'SHADOWSOCKS_PROXY',
      'HEADLESS_BROWSER'
    ].each do |key|
      value = ENV[key]
      value_display = key.include?('PASSWORD') ? (value ? '已设置(已隐藏)' : '未设置') : (value || '未设置')
      puts "#{key}: #{value_display}"
    end
    
    puts "\nDotenv库状态:"
    puts "Dotenv已加载: #{defined?(Dotenv) ? '是' : '否'}"
    
    if defined?(Dotenv)
      begin
        # 重新加载.env并检查是否成功
        before_keys = ENV.keys
        Dotenv.load(env_file)
        after_keys = ENV.keys
        new_keys = after_keys - before_keys
        
        puts "重新加载.env后新增的环境变量键: #{new_keys.join(', ')}"
      rescue => e
        puts "重新加载.env出错: #{e.message}"
      end
    end
    
    puts "\nGemfile包含dotenv: #{File.read(Rails.root.join('Gemfile')).include?('dotenv')}"
    puts "\n==== 诊断结束 ===="
  end
end 