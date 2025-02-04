require 'rails_helper'

RSpec.describe "Games", type: :request do
  describe "GET /games" do
    it "returns http success" do
      get "/games"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /games/:id" do
    let!(:game) { Game.new([ "Pedro", "Auro", "Leon" ], { "1, 4" => "trump" }) }

    it "returns http success" do
      get "/games/#{game.id}"
      expect(response).to have_http_status(:success)
    end
  end
end
