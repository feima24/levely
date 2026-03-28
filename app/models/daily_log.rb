class DailyLog < ApplicationRecord
  belongs_to :user
  has_many :learning_items, dependent: :destroy
end
