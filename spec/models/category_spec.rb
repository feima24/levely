require "rails_helper"

RSpec.describe Category, type: :model do
  describe "バリデーション" do
    let(:user) { User.create!(email: "test@example.com", password: "password123") }

    context "nameが空の場合" do
      it "無効である" do
        category = Category.new(user: user, name: "")
        expect(category).not_to be_valid
      end
    end

    context "nameがある場合" do
      it "有効である" do
        category = Category.new(user: user, name: "Ruby")
        expect(category).to be_valid
      end
    end

    context "同じユーザーで同じnormalized_nameの場合" do
      it "無効である" do
        Category.create!(user: user, name: "Ruby")
        duplicate = Category.new(user: user, name: "ruby")
        expect(duplicate).not_to be_valid
      end
    end

    context "別ユーザーで同じnormalized_nameの場合" do
      it "有効である" do
        Category.create!(user: user, name: "Ruby")
        other_user = User.create!(email: "other@example.com", password: "password123")
        other = Category.new(user: other_user, name: "Ruby")
        expect(other).to be_valid
      end
    end

    context "nameに前後スペースや大文字が含まれる場合" do
      it "normalized_nameが正規化される" do
        category = Category.create!(user: user, name: "  Ruby  On  Rails  ")
        expect(category.normalized_name).to eq("ruby on rails")
      end
    end
  end
end
