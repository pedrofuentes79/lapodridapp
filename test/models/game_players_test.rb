require "test_helper"

class GamePlayersTest < ActiveSupport::TestCase
  def setup
    @players = [ "Pedro", "Auro", "Leon" ]
    @game_players = GamePlayers.new(@players)
    @starting_player = "Pedro"
  end

  test "is valid with string players" do
    assert @game_players.valid?
  end

  test "is not valid with empty array" do
    game_players = GamePlayers.new([])
    assert_not game_players.valid?
    assert_includes game_players.errors.full_messages, "Players can't be blank"
  end

  test "is not valid with non-string players" do
    game_players = GamePlayers.new([ 1, 2, 3 ])
    assert_not game_players.valid?
    assert_includes game_players.errors.full_messages, "Players must all be strings"
  end

  test "is not valid with mixed string and non-string players" do
    game_players = GamePlayers.new([ "Player1", 2, "Player3" ])
    assert_not game_players.valid?
    assert_includes game_players.errors.full_messages, "Players must all be strings"
  end

  test "can get next player" do
    assert_equal "Auro", @game_players.next_player_to("Pedro")
    assert_equal "Leon", @game_players.next_player_to("Auro")
    assert_equal "Pedro", @game_players.next_player_to("Leon")
  end

  test "can get next player with offset" do
    assert_equal "Leon", @game_players.next_player_to("Pedro", 2)
    assert_equal "Pedro", @game_players.next_player_to("Auro", 2)
  end

  test "can get previous player" do
    assert_equal "Leon", @game_players.next_player_to("Pedro", -1)
    assert_equal "Pedro", @game_players.next_player_to("Auro", -1)
    assert_equal "Auro", @game_players.next_player_to("Leon", -1)
  end

  test "can get last player" do
    assert_equal "Leon", @game_players.last_player(@starting_player)
  end

  test "can check if a player is the last player" do
    assert @game_players.is_last_player?("Leon", @starting_player)
    assert_not @game_players.is_last_player?("Pedro", @starting_player)
  end

  test "behaves like an array" do
    assert_equal 3, @game_players.length
    assert_equal "Pedro", @game_players[0]
    assert_equal 1, @game_players.index("Auro")

    players = []
    @game_players.each { |player| players << player }
    assert_equal @players, players
  end

  test "converts to array" do
    assert_equal @players, @game_players.to_a
  end

  test "converts to json" do
    assert_equal @players.to_json, @game_players.to_json
  end
end
