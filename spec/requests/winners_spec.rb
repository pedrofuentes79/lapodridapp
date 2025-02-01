require 'rails_helper'

RSpec.describe "Winners", type: :request do
  describe "GET /games/:id/winners" do
    it "returns http success" do
      get "/games/123/winners"
      expect(response).to have_http_status(:success)
    end
  end
end
