require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get games_url
    assert_response :success
  end

  test "should get show" do
    game = Game.new([ "Pedro", "Auro", "Leon" ], { "1, 4" => "trump" })
    get game_url(game.id)
    assert_response :success
  end
end
