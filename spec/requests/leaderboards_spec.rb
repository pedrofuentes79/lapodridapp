require 'rails_helper'

RSpec.describe "Leaderboards", type: :request do
  describe "GET /api/games/:id/leaderboard" do
    let!(:game) { Game.new([ "Pedro", "Auro", "Leon" ], { "1, 4" => "trump" }) }

    it "returns http success" do
      get "/api/games/#{game.id}/leaderboard"
      expect(response).to have_http_status(:success)
    end
  end
end
