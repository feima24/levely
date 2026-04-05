require 'rails_helper'

RSpec.describe DailyLog, type: :model do
  describe 'バリデーション' do
    let(:user) { User.create!(email: 'test@example.com', password: 'password123') }

    context 'dateがある場合' do
      it '有効である' do
        daily_log = DailyLog.new(user: user, date: Time.zone.today)
        expect(daily_log).to be_valid
      end
    end

    context 'dateがない場合' do
      it '無効である' do
        daily_log = DailyLog.new(user: user, date: nil)
        expect(daily_log).not_to be_valid
      end
    end

    context '同じユーザーで同じdateが存在する場合' do
      it '無効である' do
        DailyLog.create!(user: user, date: Time.zone.today)
        duplicate = DailyLog.new(user: user, date: Time.zone.today)
        expect(duplicate).not_to be_valid
      end
    end

    context '別ユーザーで同じdateの場合' do
      it '有効である' do
        DailyLog.create!(user: user, date: Time.zone.today)
        other_user = User.create!(email: 'other@example.com', password: 'password123')
        other = DailyLog.new(user: other_user, date: Time.zone.today)
        expect(other).to be_valid
      end
    end
  end
end
