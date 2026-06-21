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
end
