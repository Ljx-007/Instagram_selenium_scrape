class RemoveCommentsCountFromInstagramPosts < ActiveRecord::Migration[8.0]
  def change
    remove_column :instagram_posts, :comments_count, :integer
  end
end
