class Category < ApplicationRecord
  belongs_to :user
  has_many :learning_items, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :normalized_name, uniqueness: { scope: :user_id }

  before_validation :normalize_name

  private

  def normalize_name
    self.normalized_name = name.to_s.strip.gsub(/\s+/, ' ').downcase
  end
end
