require 'rails_helper'

RSpec.describe "Winners", type: :request do
  describe "GET /games/:id/winners" do
    let!(:game) { Game.new([ "Pedro", "Auro", "Leon" ], { "1, 4" => "trump" }) }

    it "returns http success" do
      get "/games/#{game.id}/winners"
      expect(response).to have_http_status(:success)
    end
  end
end
