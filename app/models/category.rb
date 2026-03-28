class Category < ApplicationRecord
  belongs_to :user
  has_many :learning_items, dependent: :restrict_with_exception
end
