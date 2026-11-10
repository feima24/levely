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

  describe 'POST /monthly_goals' do
    context '自分の月間目標を作成した場合' do
      it '201になり、作成した内容が返る' do
        post '/monthly_goals', params: {
          month: month,
          monthly_goal: { goal1: '目標1', goal2: '目標2', goal3: '目標3' }
        }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body['goal1']).to eq '目標1'
        expect(response.parsed_body['rank']).to eq 'none'
        expect(user.monthly_goals.find_by(month: Date.iso8601("#{month}-01"))).to be_present
      end
    end

    context '目標が未入力の場合' do
      it '422になり、エラーが返る' do
        post '/monthly_goals', params: {
          month: month,
          monthly_goal: { goal1: '', goal2: '目標2', goal3: '目標3' }
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body['errors']).to be_present
      end
    end
  end

  describe 'PATCH /monthly_goals/:month' do
    let!(:goal) do
      MonthlyGoal.create!(user: user, month: Date.iso8601("#{month}-01"),
                          goal1: '目標1', goal2: '目標2', goal3: '目標3')
    end

    context '自分の月間目標を更新した場合' do
      it '200になり、更新した内容が返る' do
        patch "/monthly_goals/#{month}", params: { monthly_goal: { goal1: '更新後の目標1' } }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['goal1']).to eq '更新後の目標1'
        expect(goal.reload.goal1).to eq '更新後の目標1'
      end
    end
  end

  describe 'DELETE /monthly_goals/:month' do
    let!(:goal) do
      MonthlyGoal.create!(user: user, month: Date.iso8601("#{month}-01"),
                          goal1: '目標1', goal2: '目標2', goal3: '目標3')
    end

    context '自分の月間目標を削除した場合' do
      it '204になり、削除される' do
        delete "/monthly_goals/#{month}"

        expect(response).to have_http_status(:no_content)
        expect(MonthlyGoal.exists?(goal.id)).to be false
      end
    end
  end

  describe 'PATCH /monthly_goals/:month/toggle' do
    let!(:goal) do
      MonthlyGoal.create!(user: user, month: Date.iso8601("#{month}-01"),
                          goal1: '目標1', goal2: '目標2', goal3: '目標3')
    end

    context '自分の目標の達成状態を切り替えた場合' do
      it '200になり、達成状態とランクが更新される' do
        patch "/monthly_goals/#{month}/toggle", params: { goal_number: 1 }

        expect(response).to have_http_status(:ok)
        expect(goal.reload.completed1).to be true
        expect(response.parsed_body['rank']).to eq 'bronze'
      end
    end

    context '不正なgoal_numberを指定した場合' do
      it '400になり、達成状態は変わらない' do
        patch "/monthly_goals/#{month}/toggle", params: { goal_number: 4 }

        expect(response).to have_http_status(:bad_request)
        expect(goal.reload.completed1).to be false
      end
    end
  end
end
