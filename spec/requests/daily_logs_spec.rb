require 'rails_helper'

RSpec.describe 'DailyLogs', type: :request do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', confirmed_at: Time.current) }
  let(:other_user) { User.create!(email: 'other@example.com', password: 'password123', confirmed_at: Time.current) }
  let(:date) { Time.zone.today }

  before { sign_in user }

  describe 'GET /daily_logs/:date' do
    it 'HTML形式ではその月のmonthlyページにリダイレクトされる' do
      get daily_log_path(date)

      expect(response).to redirect_to(monthly_path(date.strftime('%Y-%m')))
    end

    it 'JSON形式では記録が無い場合 has_record: false を返す' do
      get daily_log_path(date), as: :json

      json = response.parsed_body
      expect(json['has_record']).to be false
      expect(json['learning_items']).to eq []
    end

    it 'JSON形式では記録がある場合その内容を返す' do
      category = Category.create!(user: user, name: 'Ruby')
      daily_log = DailyLog.create!(user: user, date: date, insights: '今日の振り返り')
      LearningItem.create!(daily_log: daily_log, category: category, summary: '学習内容', duration_minutes: 30)

      get daily_log_path(date), as: :json

      json = response.parsed_body
      expect(json['has_record']).to be true
      expect(json['insights']).to eq '今日の振り返り'
      expect(json['learning_items'].first['summary']).to eq '学習内容'
    end

    context '同じ日付に他ユーザーの記録がある場合' do
      it '他ユーザーの内容は含まれず、自分の記録として扱われる' do
        DailyLog.create!(user: other_user, date: date, insights: '他ユーザーの振り返り')

        get daily_log_path(date), as: :json

        json = response.parsed_body
        expect(json['has_record']).to be false
        expect(json['insights']).to be_nil
      end
    end
  end

  describe 'PATCH /daily_logs/:date' do
    it '記録が無い場合は新規作成される' do
      expect do
        patch daily_log_path(date), params: { insights: '今日の振り返り' }
      end.to change(DailyLog, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(user.daily_logs.find_by(date: date).insights).to eq '今日の振り返り'
    end

    it '既存の記録がある場合は新規作成せず更新される' do
      DailyLog.create!(user: user, date: date, insights: '元の内容')

      expect do
        patch daily_log_path(date), params: { insights: '更新後の内容' }
      end.not_to change(DailyLog, :count)

      expect(user.daily_logs.find_by(date: date).insights).to eq '更新後の内容'
    end

    context '同じ日付に他ユーザーの記録がある場合' do
      it '他ユーザーの記録は変更されず、自分の記録が新規作成される' do
        other_log = DailyLog.create!(user: other_user, date: date, insights: '他ユーザーの元の内容')

        patch daily_log_path(date), params: { insights: '自分の内容' }

        expect(response).to have_http_status(:ok)
        expect(other_log.reload.insights).to eq '他ユーザーの元の内容'
        expect(user.daily_logs.find_by(date: date).insights).to eq '自分の内容'
      end
    end
  end
end
