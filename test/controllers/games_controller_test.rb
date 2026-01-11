require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  test "index shows games list" do
    Game.create_game(players: %w[Alice Bob], cards_per_round: [ 3 ])

    get games_path
    assert_response :success
    assert_select "h1", "Games"
  end

  test "new shows form" do
    get new_game_path
    assert_response :success
    assert_select "h1", "New Game"
    assert_select "input[name=players]"
    assert_select "input[name=cards]"
  end

  test "create creates game and redirects" do
    assert_difference "Game.count", 1 do
      post games_path, params: {
        players: "Alice, Bob, Carol",
        cards: "1, 2, 3"
      }
    end

    game = Game.last
    assert_redirected_to game
    assert_equal %w[Alice Bob Carol], game.players
    assert_equal 3, game.rounds.size
  end

  test "create with invalid params redirects with alert" do
    assert_no_difference "Game.count" do
      post games_path, params: {
        players: "Solo",
        cards: "5"
      }
    end

    assert_redirected_to new_game_path
    assert_equal "Need at least 2 players", flash[:alert]
  end

  test "show displays game" do
    game = Game.create_game(players: %w[Alice Bob], cards_per_round: [ 3 ])

    get game_path(game)
    assert_response :success
    assert_select "h1", "Game ##{game.id}"
    assert_select "p", /Alice, Bob/
  end

  test "destroy deletes game" do
    game = Game.create_game(players: %w[Alice Bob], cards_per_round: [ 3 ])

    assert_difference "Game.count", -1 do
      delete game_path(game)
    end

    assert_redirected_to games_path
  end

  test "bid places bid and redirects" do
    game = Game.create_game(players: %w[Alice Bob], cards_per_round: [ 3 ])

    post bid_game_path(game), params: {
      round: 0,
      player: "Alice",
      asked: 2
    }

    assert_redirected_to game
    game.reload
    round = game.engine.rounds.first
    assert_equal 2, round.bids["Alice"]
  end

  test "bid records tricks" do
    game = Game.create_game(players: %w[Alice Bob], cards_per_round: [ 3 ])

    # First, place all bids
    round = game.engine.rounds.first
    round.place_bid("Alice", 2)
    round.place_bid("Bob", 0)
    game.save_engine!

    # Now record tricks
    post bid_game_path(game), params: {
      round: 0,
      player: "Alice",
      made: 2
    }

    assert_redirected_to game
    game.reload
    round = game.engine.rounds.first
    assert_equal 2, round.tricks_won["Alice"]
  end

  test "bid with invalid value shows error" do
    game = Game.create_game(players: %w[Alice Bob], cards_per_round: [ 3 ])

    # Alice bids 2, Bob is last and cannot bid 1 (forbidden)
    round = game.engine.rounds.first
    round.place_bid("Alice", 2)
    game.save_engine!

    # Try to bid the forbidden number
    post bid_game_path(game), params: {
      round: 0,
      player: "Bob",
      asked: 1 # forbidden
    }

    assert_redirected_to game
    assert_match(/forbidden/i, flash[:alert])
  end
end
