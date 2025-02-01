require 'rails_helper'

RSpec.describe "Leaderboards", type: :request do
  describe "GET /games/:id/leaderboard" do
    it "returns http success" do
      get "/games/123/leaderboard"
      expect(response).to have_http_status(:success)
    end
  end
end
