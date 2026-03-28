require "rails_helper"

RSpec.describe User, type: :model do
  describe "バリデーション" do
    context "パスワードが10文字以上の英数字の場合" do
      it "有効である" do
        user = User.new(email: "test@example.com", password: "password123")
        expect(user).to be_valid
      end
    end

    context "パスワードが10文字未満の場合" do
      it "無効である" do
        user = User.new(email: "test@example.com", password: "pass1")
        expect(user).not_to be_valid
      end
    end

    context "パスワードに数字が含まれない場合" do
      it "無効である" do
        user = User.new(email: "test@example.com", password: "passwordonly")
        expect(user).not_to be_valid
      end
    end

    context "パスワードに英字が含まれない場合" do
      it "無効である" do
        user = User.new(email: "test@example.com", password: "1234567890")
        expect(user).not_to be_valid
      end
    end
  end
end
