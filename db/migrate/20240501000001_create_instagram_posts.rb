class CreateInstagramPosts < ActiveRecord::Migration[8.0]
  def change
    create_table :instagram_posts do |t|
      t.references :topic, null: false, foreign_key: true
      t.string :instagram_id, null: false
      t.string :username
      t.text :caption
      t.string :image_url
      t.datetime :posted_at
      t.string :post_url
      t.text :hashtags
      t.integer :likes_count
      t.integer :comments_count
      t.boolean :is_video, default: false
      t.timestamps
    end
    add_index :instagram_posts, :instagram_id, unique: true
  end
end