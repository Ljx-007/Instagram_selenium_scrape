require 'dotenv'

class EnvManager
  class << self
    def load_env
      # 尝试加载环境变量
      env_file = Rails.root.join('.env')
      Dotenv.load(env_file) if File.exist?(env_file)
      
      # 返回已加载的环境变量状态
      {
        instagram: {
          username: ENV['INSTAGRAM_USERNAME'],
          password: ENV['INSTAGRAM_PASSWORD'],
          two_factor_code: ENV['INSTAGRAM_2FA_CODE']
        },
        proxy: {
          enabled: ENV['PROXY_ENABLED'] == 'true',
          type: ENV['PROXY_TYPE'],
          host: ENV['PROXY_HOST'],
          port: ENV['PROXY_PORT'],
          username: ENV['PROXY_USERNAME'],
          password: ENV['PROXY_PASSWORD'],
          url: ENV['SHADOWSOCKS_PROXY']
        },
        browser: {
          headless: ENV['HEADLESS_BROWSER'] == 'true',
          timeout: (ENV['BROWSER_TIMEOUT'] || 30).to_i
        },
        retries: {
          max_retries: (ENV['MAX_RETRIES'] || 2).to_i,
          retry_delay: (ENV['RETRY_DELAY'] || 2).to_i,
          max_login_attempts: (ENV['MAX_LOGIN_ATTEMPTS'] || 3).to_i
        }
      }
    end
    
    def debug_info
      # 提供环境变量调试信息
      env_file = Rails.root.join('.env')
      {
        env_file_exists: File.exist?(env_file),
        env_file_path: env_file.to_s,
        current_dir: Dir.pwd,
        env_preview: File.exist?(env_file) ? File.readlines(env_file).first(3).join : nil,
        env_size: File.exist?(env_file) ? File.size(env_file) : 0,
        rails_env: Rails.env,
        dotenv_loaded: defined?(Dotenv),
        env_keys: ENV.keys.select { |k| k.start_with?('INSTAGRAM', 'PROXY', 'HEADLESS') }
      }
    end
  end
end 