require 'rails_helper'

RSpec.describe LearningItem, type: :model do
  describe 'バリデーション' do
    let(:user) { User.create!(email: 'test@example.com', password: 'password123') }
    let(:daily_log) { DailyLog.create!(user: user, date: Time.zone.today) }
    let(:category) { Category.create!(user: user, name: 'Ruby') }

    context 'カテゴリと概要がある場合' do
      it '学習時間なしでも有効である' do
        item = LearningItem.new(daily_log: daily_log, category: category, summary: '学習内容')
        expect(item).to be_valid
      end

      it '学習時間ありでも有効である' do
        item = LearningItem.new(daily_log: daily_log, category: category, summary: '学習内容', duration_minutes: 60)
        expect(item).to be_valid
      end
    end

    context 'カテゴリがない場合' do
      it '無効である' do
        item = LearningItem.new(daily_log: daily_log, summary: '学習内容')
        expect(item).not_to be_valid
        expect(item.errors[:category]).to be_present
      end
    end

    context '概要がない場合' do
      it '無効である' do
        item = LearningItem.new(daily_log: daily_log, category: category)
        expect(item).not_to be_valid
        expect(item.errors[:summary]).to be_present
      end
    end

    context 'カテゴリも概要もない場合' do
      it '無効である' do
        item = LearningItem.new(daily_log: daily_log)
        expect(item).not_to be_valid
      end
    end

  end
end
