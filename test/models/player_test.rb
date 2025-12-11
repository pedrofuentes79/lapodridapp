require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  test "can participate in games" do
    game = Game.create
    player = Player.create(name: "Alice")
    game.game_participations.create(player: player, position: 1)
    
    assert_includes player.games, game
    assert_includes game.players, player
  end

  test "should require a name" do
    game = Game.create
    player = game.players.build(name: nil)
    
    assert_not player.valid?
    assert_includes player.errors[:name], "can't be blank"
  end

  test "can exist without a game" do
    player = Player.new(name: "Alice")
    
    assert player.valid?
  end

  test "should create a valid player with name" do
    player = Player.create(name: "Alice")
    
    assert player.valid?
    assert player.persisted?
  end
end
