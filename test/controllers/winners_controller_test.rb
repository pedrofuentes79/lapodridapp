require "test_helper"

class WinnersControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    game = Game.new([ "Pedro", "Auro", "Leon" ], { "1, 4" => "trump" })
    get winners_game_path(game.id)
    assert_response :success
  end
end
