class LearningItem < ApplicationRecord
  belongs_to :daily_log
  belongs_to :category

  validates :summary, presence: true, length: { maximum: 100 }
end
