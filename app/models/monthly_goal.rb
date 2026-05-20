class MonthlyGoal < ApplicationRecord
  belongs_to :user

  validates :month, presence: true, uniqueness: { scope: :user_id }
  validates :goal1, :goal2, :goal3, presence: true

  def rank
    if completed1 && completed2 && completed3
      :gold
    elsif completed1 && completed2
      :silver
    elsif completed1
      :bronze
    else
      :none
    end
  end
end
