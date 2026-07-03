require 'rails_helper'

RSpec.describe 'Monthlies', type: :request do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', confirmed_at: Time.current) }

  before { sign_in user }

  describe 'GET /monthlies/:month' do
    it 'Turboのキャッシュを無効化するmetaタグを含む' do
      get monthly_path(Time.zone.today.strftime('%Y-%m'))

      expect(response.body).to include('name="turbo-cache-control" content="no-cache"')
    end
  end
end
