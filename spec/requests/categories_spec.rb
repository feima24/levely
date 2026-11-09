require 'rails_helper'

RSpec.describe 'Categories', type: :request do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', confirmed_at: Time.current) }
  let(:other_user) { User.create!(email: 'other@example.com', password: 'password123', confirmed_at: Time.current) }

  before { sign_in user }

  describe 'PATCH /categories/:id' do
    context '他ユーザーのカテゴリに対してPATCHした場合' do
      let(:other_category) { Category.create!(user: other_user, name: '相手のカテゴリ') }

      it '404になり、相手のカテゴリは変更されない' do
        patch "/categories/#{other_category.id}", params: { category: { name: '乗っ取り' } }

        expect(response).to have_http_status(:not_found)
        expect(other_category.reload.name).to eq '相手のカテゴリ'
      end
    end
  end
end
