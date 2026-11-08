require 'rails_helper'

RSpec.describe 'LearningItems', type: :request do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', confirmed_at: Time.current) }

  before { sign_in user }

  describe 'POST /learning_items' do
    let(:params) do
      {
        date: Time.zone.today.iso8601,
        learning_item: {
          category_name: 'Ruby',
          summary: 'テスト学習内容',
          duration_minutes: 60,
          client_uuid: 'test-uuid-123'
        }
      }
    end

    context '同じ client_uuid で複数回POSTした場合' do
      it '1件しか作成されず、2回目は既存レコードを返す' do
        post '/learning_items', params: params
        expect(response).to have_http_status(:created)

        expect do
          post '/learning_items', params: params
        end.not_to change(LearningItem, :count)

        expect(response).to have_http_status(:ok)
        expect(LearningItem.where(client_uuid: 'test-uuid-123').count).to eq 1
      end
    end
  end

  describe 'PATCH /learning_items/:id' do
    let(:category) { Category.create!(user: user, name: 'Ruby') }
    let(:daily_log) { DailyLog.create!(user: user, date: Time.zone.today) }
    let(:item) do
      LearningItem.create!(daily_log: daily_log, category: category, summary: '元の内容', duration_minutes: 30)
    end

    it '通常の更新は成功する' do
      params = { learning_item: { summary: '更新後の内容', lock_version: item.lock_version } }
      patch "/learning_items/#{item.id}", params: params

      expect(response).to have_http_status(:ok)
      expect(item.reload.summary).to eq '更新後の内容'
    end

    it '古いlock_versionで更新すると409 conflictになる' do
      stale_lock_version = item.lock_version
      item.update!(summary: '他の端末での更新')
      params = { learning_item: { summary: '古い内容での更新', lock_version: stale_lock_version } }

      patch "/learning_items/#{item.id}", params: params

      expect(response).to have_http_status(:conflict)
      expect(item.reload.summary).to eq '他の端末での更新'
    end
  end

  describe 'DELETE /learning_items/:id' do
    let(:category) { Category.create!(user: user, name: 'Ruby') }

    it '記録が他に残っていればdaily_logは削除されない' do
      daily_log = DailyLog.create!(user: user, date: Time.zone.today)
      item = LearningItem.create!(daily_log: daily_log, category: category, summary: '削除対象')
      LearningItem.create!(daily_log: daily_log, category: category, summary: '残る項目')

      delete "/learning_items/#{item.id}"

      expect(response).to have_http_status(:no_content)
      expect(DailyLog.exists?(daily_log.id)).to be true
    end

    it '最後の項目でinsightsも無ければdaily_logも削除される' do
      daily_log = DailyLog.create!(user: user, date: Time.zone.today)
      item = LearningItem.create!(daily_log: daily_log, category: category, summary: '削除対象')

      delete "/learning_items/#{item.id}"

      expect(response).to have_http_status(:no_content)
      expect(DailyLog.exists?(daily_log.id)).to be false
    end

    it '最後の項目でもinsightsが残っていればdaily_logは削除されない' do
      daily_log = DailyLog.create!(user: user, date: Time.zone.today, insights: '振り返りメモ')
      item = LearningItem.create!(daily_log: daily_log, category: category, summary: '削除対象')

      delete "/learning_items/#{item.id}"

      expect(response).to have_http_status(:no_content)
      expect(DailyLog.exists?(daily_log.id)).to be true
    end
  end
end
