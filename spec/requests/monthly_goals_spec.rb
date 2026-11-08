require 'rails_helper'

RSpec.describe 'MonthlyGoals', type: :request do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', confirmed_at: Time.current) }
  let(:other_user) { User.create!(email: 'other@example.com', password: 'password123', confirmed_at: Time.current) }
  let(:month) { Time.zone.today.strftime('%Y-%m') }
  let!(:other_goal) do
    MonthlyGoal.create!(user: other_user, month: Date.iso8601("#{month}-01"),
                        goal1: '相手の目標1', goal2: '相手の目標2', goal3: '相手の目標3')
  end

  before { sign_in user }

  describe '他ユーザーの月間目標に対する操作' do
    it 'PATCHしても404になり、相手の目標は変更されない' do
      patch "/monthly_goals/#{month}", params: { monthly_goal: { goal1: '乗っ取り' } }

      expect(response).to have_http_status(:not_found)
      expect(other_goal.reload.goal1).to eq '相手の目標1'
    end

    it 'DELETEしても404になり、相手の目標は削除されない' do
      delete "/monthly_goals/#{month}"

      expect(response).to have_http_status(:not_found)
      expect(MonthlyGoal.exists?(other_goal.id)).to be true
    end

    it 'toggleしても404になり、相手の達成状態は変わらない' do
      patch "/monthly_goals/#{month}/toggle", params: { goal_number: 1 }

      expect(response).to have_http_status(:not_found)
      expect(other_goal.reload.completed1).to be false
    end
  end
end
