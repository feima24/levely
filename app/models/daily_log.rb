class DailyLog < ApplicationRecord
  belongs_to :user
  has_many :learning_items, dependent: :destroy

  validates :date, presence: true, uniqueness: { scope: :user_id }
end
