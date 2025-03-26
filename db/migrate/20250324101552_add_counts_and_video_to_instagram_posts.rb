class AddCountsAndVideoToInstagramPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :instagram_posts, :likes_count, :integer
    add_column :instagram_posts, :comments_count, :integer
  end
end
