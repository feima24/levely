require 'rails_helper'

RSpec.describe "LearningItems", type: :request do
  describe "GET /create" do
    it "returns http success" do
      get "/learning_items/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/learning_items/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/learning_items/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
