class RestructureInstagramPostsTable < ActiveRecord::Migration[7.0]
  def up
    # 删除旧表
    drop_table :instagram_posts if table_exists?(:instagram_posts)

    # 创建新表，只包含必要字段
    create_table :instagram_posts do |t|
      t.references :topic, null: false, foreign_key: true
      t.string :instagram_id, null: false
      t.string :username
      t.text :caption
      t.string :image_url
      t.datetime :posted_at
      t.integer :likes_count
      t.string :post_url
      t.text :hashtags

      t.timestamps
    end

    # 添加必要的索引
    add_index :instagram_posts, :instagram_id, unique: true
  end

  def down
    drop_table :instagram_posts if table_exists?(:instagram_posts)
  end
end
