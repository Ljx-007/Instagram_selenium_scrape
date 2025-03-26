namespace :db do
    desc "清除所有 Instagram 帖子数据"
    task clear_instagram_posts: :environment do
      begin
        # 删除所有 Instagram 帖子
        InstagramPost.delete_all
        
        # 删除图片文件
        storage_dir = Rails.root.join('app', 'assets', 'images', 'instagram_images')
        if Dir.exist?(storage_dir)
          FileUtils.rm_rf(storage_dir)
          FileUtils.mkdir_p(storage_dir)
        end
        
        puts "成功清除所有 Instagram 帖子数据"
      rescue => e
        puts "清除数据时出错: #{e.message}"
      end
    end
  end