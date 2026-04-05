require 'rails_helper'

RSpec.describe LearningItem, type: :model do
  describe 'バリデーション' do
    let(:user) { User.create!(email: 'test@example.com', password: 'password123') }
    let(:daily_log) { DailyLog.create!(user: user, date: Time.zone.today) }
    let(:category) { Category.create!(user: user, name: 'Ruby') }

    context '本文と学習時間の両方がある場合' do
      it '有効である' do
        item = LearningItem.new(daily_log: daily_log, category: category, body_markdown: '学習内容', duration_minutes: 60)
        expect(item).to be_valid
      end
    end

    context '本文のみある場合' do
      it '有効である' do
        item = LearningItem.new(daily_log: daily_log, category: category, body_markdown: '学習内容')
        expect(item).to be_valid
      end
    end

    context '学習時間のみある場合' do
      it '有効である' do
        item = LearningItem.new(daily_log: daily_log, category: category, duration_minutes: 60)
        expect(item).to be_valid
      end
    end

    context '本文と学習時間の両方がない場合' do
      it '無効である' do
        item = LearningItem.new(daily_log: daily_log, category: category)
        expect(item).not_to be_valid
      end
    end
  end
end
