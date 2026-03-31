require 'rails_helper'

RSpec.describe "DailyLogs", type: :request do
  describe "GET /show" do
    it "returns http success" do
      get "/daily_logs/show"
      expect(response).to have_http_status(:success)
    end
  end

end
