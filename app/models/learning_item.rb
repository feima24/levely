class LearningItem < ApplicationRecord
  belongs_to :daily_log
  belongs_to :category, optional: true

  validate :any_field_present

  private

  def any_field_present
    return if category_id.present? || summary.present? || duration_minutes.present?

    errors.add(:base, 'カテゴリ・概要・学習時間のいずれかを入力してください')
  end
end
