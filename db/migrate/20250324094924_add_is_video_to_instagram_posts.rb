class AddIsVideoToInstagramPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :instagram_posts, :is_video, :boolean
  end
end
