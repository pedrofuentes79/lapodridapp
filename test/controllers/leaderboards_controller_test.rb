require "test_helper"

class LeaderboardsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    game = Game.new(["Pedro", "Auro", "Leon"], { "1, 4" => "trump" })
    
    # Add some game state to test leaderboard calculation
    game_state = {
      "current_round_number" => 1,
      "rounds" => {
        "1" => {
          "asked_tricks" => { "Pedro" => 2, "Auro" => 1, "Leon" => 0 },
          "tricks_made" => { "Pedro" => 2, "Auro" => 1, "Leon" => 1 }
        }
      }
    }
    
    game.update_state(game_state)
    
    get leaderboard_api_game_path(game.id)
    assert_response :success
    
    # Parse and verify the response
    response_data = JSON.parse(@response.body)
    assert_kind_of Hash, response_data
    assert_includes response_data.keys, "Pedro"
    assert_includes response_data.keys, "Auro"
    assert_includes response_data.keys, "Leon"
  end
end
