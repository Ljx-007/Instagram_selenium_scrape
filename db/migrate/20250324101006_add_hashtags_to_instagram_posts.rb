class AddHashtagsToInstagramPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :instagram_posts, :hashtags, :text
  end
end
