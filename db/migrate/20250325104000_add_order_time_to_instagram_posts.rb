class AddOrderTimeToInstagramPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :instagram_posts, :order_time, :datetime
    add_index :instagram_posts, :order_time
  end
end 