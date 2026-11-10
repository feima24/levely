class DailyLog < ApplicationRecord
  belongs_to :user
  has_many :learning_items, dependent: :destroy
  has_one :daily_log_embedding, dependent: :destroy

  validates :date, presence: true, uniqueness: { scope: :user_id }
  validates :insights, length: { maximum: 5000 }

  def recorded?
    learning_items.any? || insights.present?
  end
end
