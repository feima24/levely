require 'rails_helper'

RSpec.describe 'Monthlies', type: :request do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', confirmed_at: Time.current) }

  describe 'GET /monthlies/:month' do
    context '未ログインの場合' do
      it 'ログイン画面にリダイレクトされる' do
        get monthly_path(Time.zone.today.strftime('%Y-%m'))

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'ログイン済みの場合' do
      before { sign_in user }

      it 'Turboのキャッシュを無効化するmetaタグを含む' do
        get monthly_path(Time.zone.today.strftime('%Y-%m'))

        expect(response.body).to include('name="turbo-cache-control" content="no-cache"')
      end

      it '学習記録がある月を表示できる' do
        category = Category.create!(user: user, name: 'Ruby')
        daily_log = DailyLog.create!(user: user, date: Time.zone.today)
        LearningItem.create!(daily_log: daily_log, category: category, summary: '学習内容', duration_minutes: 60)

        get monthly_path(Time.zone.today.strftime('%Y-%m'))

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
