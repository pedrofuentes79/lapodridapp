require 'rails_helper'

RSpec.describe "Games", type: :request do
  describe "GET /games" do
    it "returns http success" do
      get "/games"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /games/:id" do
    it "returns http success" do
      get "/games/123"
      expect(response).to have_http_status(:success)
    end
  end
end
