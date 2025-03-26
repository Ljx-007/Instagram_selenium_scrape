class AddPostUrlToInstagramPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :instagram_posts, :post_url, :string
  end
end
