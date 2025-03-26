class ChangePostedAtToString < ActiveRecord::Migration[7.1]
  def up
    change_column :instagram_posts, :posted_at, :string
  end

  def down
    change_column :instagram_posts, :posted_at, :datetime
  end
end
