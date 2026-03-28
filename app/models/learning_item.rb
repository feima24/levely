class LearningItem < ApplicationRecord
  belongs_to :daily_log
  belongs_to :category

  validate :body_or_duration_present

  private

  def body_or_duration_present
    return if body_markdown.present? || duration_minutes.present?

    errors.add(:base, "学習ログか学習時間のどちらかを入力してください")
  end
end
