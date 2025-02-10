require "test_helper"

class LeaderboardsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    game = Game.new([ "Pedro", "Auro", "Leon" ], { "1, 4" => "trump" })
    get leaderboard_api_game_path(game.id)
    assert_response :success
  end
end
