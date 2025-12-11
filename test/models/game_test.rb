require "test_helper"

class GameTest < ActiveSupport::TestCase
  test "should create a game" do
    game = Game.create
    assert game.persisted?
  end

  test "should have many players through game_participations" do
    game = Game.create
    player1 = Player.create(name: "Alice")
    player2 = Player.create(name: "Bob")
    game.game_participations.create(player: player1, position: 1)
    game.game_participations.create(player: player2, position: 2)
    
    assert_equal 2, game.players.count
    assert_includes game.players, player1
    assert_includes game.players, player2
  end

  test "should have many rounds" do
    game = Game.create
    round1 = game.rounds.create(cards_dealt: 7, round_number: 1)
    round2 = game.rounds.create(cards_dealt: 6, round_number: 2)
    
    assert_equal 2, game.rounds.count
    assert_includes game.rounds, round1
    assert_includes game.rounds, round2
  end

  test "should destroy associated rounds when game is destroyed" do
    game = Game.create
    round = game.rounds.create(cards_dealt: 7, round_number: 1)
    round_id = round.id
    
    game.destroy
    
    assert_nil Round.find_by(id: round_id)
  end

  test "should raise if trying to make/ask tricks if previous round isn't complete" do
    game = Game.create
    alice = Player.create(name: "Alice")
    bob = Player.create(name: "Bob")
    game.game_participations.create(player: alice, position: 1)
    game.game_participations.create(player: bob, position: 2)

    round1 = game.rounds.create(cards_dealt: 7, round_number: 0)
    round2 = game.rounds.create(cards_dealt: 6, round_number: 1)
    
    game.ask_for_tricks(round1, alice, 2)
    game.ask_for_tricks(round1, bob, 3)
    game.make_tricks(round1, alice, 3)

    assert !round1.complete?
    assert !game.is_previous_round_complete?(round2)

    error = assert_raises(RuntimeError) do
      game.ask_for_tricks(round2, alice, 2)
    end
    assert_equal "Previous round hasn't been completed yet", error.message

    error = assert_raises(RuntimeError) do
      game.make_tricks(round2, alice, 2)
    end
    assert_equal "Previous round hasn't been completed yet", error.message
  end

end
