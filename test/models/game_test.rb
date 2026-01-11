require "test_helper"

class GameTest < ActiveSupport::TestCase
  test "create_game creates a game with engine state" do
    game = Game.create_game(
      players: %w[Alice Bob Carol],
      cards_per_round: [ 1, 2, 3 ]
    )

    assert game.persisted?
    assert_equal %w[Alice Bob Carol], game.players
    assert_equal 3, game.rounds.size
  end

  test "engine returns a LaPodrida::Tracking::Game instance" do
    game = Game.create_game(
      players: %w[Alice Bob],
      cards_per_round: [ 5 ]
    )

    assert_kind_of LaPodrida::Tracking::Game, game.engine
  end

  test "save_engine! persists engine state changes" do
    game = Game.create_game(
      players: %w[Alice Bob],
      cards_per_round: [ 5 ]
    )

    round = game.engine.rounds.first
    round.place_bid("Alice", 2)
    round.place_bid("Bob", 2)
    game.save_engine!

    # Reload and verify state was persisted
    game.reload
    round = game.engine.rounds.first
    assert_equal({ "Alice" => 2, "Bob" => 2 }, round.bids)
  end

  test "delegates methods to engine" do
    game = Game.create_game(
      players: %w[Alice Bob Carol],
      cards_per_round: [ 3, 2, 1 ]
    )

    assert_equal %w[Alice Bob Carol], game.players
    assert_equal 3, game.rounds.size
    assert_equal({ "Alice" => 0, "Bob" => 0, "Carol" => 0 }, game.scores)
    refute game.complete?
    assert_nil game.winner
  end

  test "complete game has winner" do
    game = Game.create_game(
      players: %w[Alice Bob],
      cards_per_round: [ 3 ]
    )

    round = game.engine.rounds.first
    round.place_bid("Alice", 2)
    round.place_bid("Bob", 0)
    round.record_tricks("Alice", 2)
    round.record_tricks("Bob", 1)

    assert game.engine.complete?
    assert_equal "Alice", game.engine.winner
  end

  test "rejects invalid player count" do
    assert_raises(ArgumentError) do
      Game.create_game(
        players: %w[Solo],
        cards_per_round: [ 5 ]
      )
    end
  end

  test "rejects invalid card count" do
    assert_raises(ArgumentError) do
      Game.create_game(
        players: %w[Alice Bob],
        cards_per_round: [ 0 ]
      )
    end
  end
end
