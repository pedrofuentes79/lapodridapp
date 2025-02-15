require "test_helper"

class GameTest < ActiveSupport::TestCase
  def setup
    @players = [ "Pedro", "Auro", "Leon" ]
    @rounds = { "1, 4" => "trump", "2, 5" => "trump", "3, 4" => "trump" }
    @game = Game.new(@players, @rounds)
  end

  test "is valid with valid attributes" do
    game = Game.new(@players)
    assert game.valid?
  end
  # By the way, the players array is validated in the GamePlayers model

  test "works with players and without rounds" do
    game = Game.new(@players)
    assert_equal @players, game.players.to_a
    assert_nil game.rounds
  end

  test "sets up initial state when valid" do
    game = Game.new(@players)
    assert_not_nil game.id
    assert_nil game.started
  end

  test "does not set up game state when invalid" do
    game = Game.new([ 1, 2, 3 ])  # invalid players
    assert_not_nil game.id  # ID is always set
    assert_nil game.rounds
    assert_nil game.current_round
  end

  test "generates a unique UUID for each game" do
    game1 = Game.new(@players)
    game2 = Game.new(@players)
    assert_not_equal game1.id, game2.id
    assert_match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/, game1.id)
  end

  test "can find a game by id" do
    game = Game.new(@players)
    assert_equal game, Game.find(game.id)
  end

  test "returns nil when finding non-existent game" do
    assert_nil Game.find("non-existent-id")
  end

  test "is created also by passing the rounds" do
    round1 = @game.current_round
    assert_equal 1, round1.round_number
    assert_equal 4, round1.amount_of_cards
    assert round1.is_trump?

    round2 = @game.next_round
    assert_equal 2, round2.round_number
    assert_equal 5, round2.amount_of_cards
    assert round2.is_trump?

    round3 = @game.next_round
    assert_equal 3, round3.round_number
    assert_equal 4, round3.amount_of_cards
    assert round3.is_trump?

    assert_instance_of NullRound, @game.next_round
  end

  test "allows players to ask for tricks" do
    @game.start()
    @game.update_state({ "rounds" => { "1" =>
      { "asked_tricks" => { "Pedro" => 1, "Auro" => 2, "Leon" => 0 } }
    } })
    assert_equal({ "Pedro" => 1, "Auro" => 2, "Leon" => 0 }, @game.current_round.asked_tricks)
  end

  test "does not allow last player to ask for tricks if total sum equals amount of cards per round" do
    @game.start()
    assert_raises(ArgumentError) do
      @game.update_state({ "rounds" => { "1" =>
        { "asked_tricks" => { "Pedro" => 1, "Auro" => 2, "Leon" => 1 } }
      } })
    end
  end

  test "allows player to register how many tricks they made" do
    @game.start()
    @game.update_state({ "rounds" => { "1" =>
      { "asked_tricks" => { "Pedro" => 1, "Auro" => 2, "Leon" => 0 },
        "tricks_made" => { "Pedro" => 1, "Auro" => 2, "Leon" => 1 }
      }
    } })
    assert_equal({ "Pedro" => 1, "Auro" => 2, "Leon" => 1 }, @game.current_round.tricks_made)
  end

  test "does not allow a player to register more tricks than the amount of cards per round" do
    @game.start()
    assert_raises(ArgumentError) do
      @game.update_state({ "rounds" => { "1" =>
        { "asked_tricks" => { "Pedro" => 1, "Auro" => 2, "Leon" => 0 },
          "tricks_made" => { "Pedro" => 5 } }
      } })
    end
  end

  test "does not allow a player to register less than 0 tricks" do
    @game.start()
    assert_raises(ArgumentError) do
      @game.update_state({ "rounds" => { "1" =>
        { "asked_tricks" => { "Pedro" => 1, "Auro" => 2, "Leon" => 0 },
          "tricks_made" => { "Pedro" => -1 } } } })
    end
  end

  test "does not allow a player to register tricks if all players have not asked for tricks" do
    @game.start()
    assert_raises(ArgumentError) do
      @game.update_state({ "rounds" => { "1" =>
        { "asked_tricks" => { "Pedro" => 1, "Auro" => 2, "Leon" => nil },
          "tricks_made" => { "Pedro" => 1 } } } })
    end
  end

  test "knows how many points each player had per round" do
    @game.start()
    @game.update_state({ "rounds" => { "1" =>
      { "asked_tricks" => { "Pedro" => 1, "Auro" => 2, "Leon" => 0 },
        "tricks_made" => { "Pedro" => 1, "Auro" => 2, "Leon" => 1 } } } })

    assert_equal({ "Pedro" => 12, "Auro" => 14, "Leon" => 1 }, @game.current_round.points)
  end
end
