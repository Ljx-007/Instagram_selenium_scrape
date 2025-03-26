class Topic < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  has_many :instagram_posts, dependent: :destroy
  
  def self.find_or_create_by_name(name)
    where(name: name).first_or_create
  end
end