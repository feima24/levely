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

    context '自分のカテゴリを更新した場合' do
      let(:category) { Category.create!(user: user, name: '元の名前') }

      it '更新されて一覧にリダイレクトされる' do
        patch "/categories/#{category.id}", params: { category: { name: '新しい名前' } }

        expect(response).to redirect_to(categories_path)
        expect(category.reload.name).to eq '新しい名前'
      end
    end

    context '名前を空で更新した場合' do
      let(:category) { Category.create!(user: user, name: '元の名前') }

      it '422になり、名前は変更されない' do
        patch "/categories/#{category.id}", params: { category: { name: '' } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(category.reload.name).to eq '元の名前'
      end
    end
  end

  describe 'GET /categories' do
    it '自分のカテゴリだけが表示される' do
      Category.create!(user: user, name: '自分のカテゴリ')
      Category.create!(user: other_user, name: '相手のカテゴリ')

      get '/categories'

      expect(response.body).to include('自分のカテゴリ')
      expect(response.body).not_to include('相手のカテゴリ')
    end
  end
end
