class LearningItem < ApplicationRecord
  belongs_to :daily_log
  belongs_to :category
end
