require "test_helper"

class RoundTest < ActiveSupport::TestCase
  def setup
    @game = Game.create
    @player1 = Player.create(name: "Alice")
    @player2 = Player.create(name: "Bob")
    @player3 = Player.create(name: "Charlie")
    @game.game_participations.create(player: @player1, position: 1)
    @game.game_participations.create(player: @player2, position: 2)
    @game.game_participations.create(player: @player3, position: 3)
  end

  test "should belong to a game" do
    round = @game.rounds.create(cards_dealt: 7, round_number: 1)
    
    assert_equal @game, round.game
  end

  test "should create empty bids for each player" do
    round = @game.rounds.create(cards_dealt: 7, round_number: 1)
    
    assert_equal @game.players.count, round.bids.count
    assert_equal @game.players.pluck(:id), round.bids.pluck(:player_id)
  end

  test "should know forbidden number only when one player doesn't have a bid" do
    round = @game.rounds.create(cards_dealt: 7, round_number: 1)
    assert_nil round.forbidden_number

    round.player_asks_for_tricks(@player1, 2)
    assert_nil round.forbidden_number

    round.player_asks_for_tricks(@player2, 3)
    assert_equal 2, round.forbidden_number

    round.player_asks_for_tricks(@player3, 1)
    assert_nil round.forbidden_number
  end

  test "should know total points for a player" do
    round = @game.rounds.create(cards_dealt: 7, round_number: 1)
    round.player_asks_for_tricks(@player1, 5)
    round.player_asks_for_tricks(@player2, 3)
    round.player_asks_for_tricks(@player3, 2)
    round.player_makes_tricks(@player1, 3) 
    round.player_makes_tricks(@player2, 2)
    round.player_makes_tricks(@player3, 2)
    assert_equal 3, round.points_for_player(@player1)
    assert_equal 2, round.points_for_player(@player2)
    assert_equal 14, round.points_for_player(@player3)
  end

  test "should raise error if player asks for more tricks than the number of cards dealt" do
    round = @game.rounds.create(cards_dealt: 7, round_number: 1)
    error = assert_raises(RuntimeError) do
      round.player_asks_for_tricks(@player1, 8)
    end
    assert_equal "Invalid number of tricks", error.message
  end

  test "should raise error if player asks for the forbidden number of tricks" do
    round = @game.rounds.create(cards_dealt: 7, round_number: 1)
    @game.ask_for_tricks(round, @player1, 2)
    @game.ask_for_tricks(round, @player2, 3)
    error = assert_raises(RuntimeError) do
      @game.ask_for_tricks(round, @player3, round.forbidden_number)
    end
    assert_equal "Player #{@player3.name} can't ask for 2 tricks", error.message
  end

  test "should allow player to ask for forbidden_number + 1" do
    round = @game.rounds.create(cards_dealt: 7, round_number: 1)
    @game.ask_for_tricks(round, @player1, 2)
    @game.ask_for_tricks(round, @player2, 3)
    # forbidden_number is 2, so asking for 3 should be allowed
    assert_nothing_raised do
      @game.ask_for_tricks(round, @player3, round.forbidden_number + 1)
    end
  end

  test "should not raise if the last player to make tricks doesn't make the total number of tricks" do
    round = @game.rounds.create(cards_dealt: 7, round_number: 0)
    @game.ask_for_tricks(round, @player1, 2)
    @game.ask_for_tricks(round, @player2, 3)
    @game.ask_for_tricks(round, @player3, 1)
    @game.make_tricks(round, @player1, 2)
    @game.make_tricks(round, @player2, 3)

    # THIS IS BECAUSE WE'RE ALLOWING AN INVALID STATE TO BE CREATED AND CORRECTED LATER
    assert_nothing_raised do
      @game.make_tricks(round, @player3, 3)
    end
    assert_not round.valid_state?
  end

  test "should allow player to overwrite the tricks they asked for" do
    round = @game.rounds.create(cards_dealt: 7, round_number: 0)
    @game.ask_for_tricks(round, @player1, 2)
    @game.ask_for_tricks(round, @player2, 3)
    @game.ask_for_tricks(round, @player3, 1)
    assert_nothing_raised do
      @game.ask_for_tricks(round, @player1, 1)
    end
  end

  test "should allow last player to overwrite the tricks they asked for" do
    round = @game.rounds.create(cards_dealt: 7, round_number: 0)
    @game.ask_for_tricks(round, @player1, 2)
    @game.ask_for_tricks(round, @player2, 3)
    @game.ask_for_tricks(round, @player3, 1)
    assert_nothing_raised do
      @game.ask_for_tricks(round, @player3, 3)
    end
  end
  test "should not allow any player to overwrite asked tricks if it would make the total equal to cards_dealt" do
    round = @game.rounds.create(cards_dealt: 7, round_number: 0)
    @game.ask_for_tricks(round, @player1, 2)
    @game.ask_for_tricks(round, @player2, 3)
    @game.ask_for_tricks(round, @player3, 1)

    error = assert_raises(RuntimeError) do
      @game.ask_for_tricks(round, @player3, 2)
    end
    assert_equal "Player #{@player3.name} can't ask for 2 tricks", error.message

    error = assert_raises(RuntimeError) do
      @game.ask_for_tricks(round, @player2, 4)
    end
    assert_equal "Player #{@player2.name} can't ask for 4 tricks", error.message

    error = assert_raises(RuntimeError) do
      @game.ask_for_tricks(round, @player1, 3)
    end
    assert_equal "Player #{@player1.name} can't ask for 3 tricks", error.message
  end

  test "should allow overwriting actual_tricks when round is complete" do
    round = @game.rounds.create(cards_dealt: 7, round_number: 0)
    @game.ask_for_tricks(round, @player1, 2)
    @game.ask_for_tricks(round, @player2, 3)
    @game.ask_for_tricks(round, @player3, 3)
    @game.make_tricks(round, @player1, 2)
    @game.make_tricks(round, @player2, 3)
    @game.make_tricks(round, @player3, 2)

    # round is valid right now
    assert round.valid_state?

    assert_nothing_raised do
      # we break validity by making the total_made_tricks != cards_dealt
      @game.make_tricks(round, @player1, 1)
      assert_not round.valid_state?

      @game.make_tricks(round, @player3, 3)
      assert round.valid_state?
    end
    assert_equal 7, round.total_made_tricks
  end

  test "should not allow overwriting actual_tricks when round is complete if it would break total" do
    skip "SKIP: we're trying to allow an invalid state! So this test doesn't make sense anymore"
    round = @game.rounds.create(cards_dealt: 7, round_number: 0)
    @game.ask_for_tricks(round, @player1, 2)
    @game.ask_for_tricks(round, @player2, 3)
    @game.ask_for_tricks(round, @player3, 1)
    @game.make_tricks(round, @player1, 2)
    @game.make_tricks(round, @player2, 3)
    @game.make_tricks(round, @player3, 2)
    # Round is complete (total = 7). Try to overwrite to make total != 7
    error = assert_raises(RuntimeError) do
      @game.make_tricks(round, @player1, 5)
    end
    assert_equal "Player #{@player1.name} can only make 2 tricks", error.message
  end

  test "should allow overwriting actual_tricks for non-last player when round is not complete" do
    round = @game.rounds.create(cards_dealt: 7, round_number: 0)
    @game.ask_for_tricks(round, @player1, 2)
    @game.ask_for_tricks(round, @player2, 3)
    @game.ask_for_tricks(round, @player3, 1)
    @game.make_tricks(round, @player1, 2)
    @game.make_tricks(round, @player2, 3)
    # Round not complete yet, player1 can overwrite
    assert_nothing_raised do
      @game.make_tricks(round, @player1, 1)
    end
  end

  test "should allow overwriting actual_tricks for last player" do
    round = @game.rounds.create(cards_dealt: 7, round_number: 0)
    @game.ask_for_tricks(round, @player1, 2)
    @game.ask_for_tricks(round, @player2, 3)
    @game.ask_for_tricks(round, @player3, 1)
    @game.make_tricks(round, @player1, 2)
    @game.make_tricks(round, @player2, 3)
    @game.make_tricks(round, @player3, 2)
    # Last player can overwrite, but must maintain total
    assert_nothing_raised do
      @game.make_tricks(round, @player3, 2)
    end
  end

  test "should allow overwriting predicted_tricks that changes forbidden_number" do
    round = @game.rounds.create(cards_dealt: 7, round_number: 0)
    @game.ask_for_tricks(round, @player1, 2)
    @game.ask_for_tricks(round, @player2, 3)
    # forbidden_number is 2
    assert_equal 2, round.forbidden_number
    # Overwrite player1 to change forbidden_number
    assert_nothing_raised do
      @game.ask_for_tricks(round, @player1, 1)
    end
    # Now forbidden_number should be 3 (7 - 1 - 3 = 3)
    assert_equal 3, round.forbidden_number
  end

  test "should allow overwriting actual_tricks multiple times when round is complete" do
    round = @game.rounds.create(cards_dealt: 7, round_number: 0)
    @game.ask_for_tricks(round, @player1, 2)
    @game.ask_for_tricks(round, @player2, 3)
    @game.ask_for_tricks(round, @player3, 1)
    @game.make_tricks(round, @player1, 2)
    @game.make_tricks(round, @player2, 3)
    @game.make_tricks(round, @player3, 2)
    # Multiple overwrites that maintain total
    assert_nothing_raised do
      @game.make_tricks(round, @player1, 1)
      @game.make_tricks(round, @player2, 4)
      @game.make_tricks(round, @player3, 2)
      @game.make_tricks(round, @player1, 3)
      @game.make_tricks(round, @player2, 2)
      @game.make_tricks(round, @player3, 2)
    end
    assert_equal 7, round.total_made_tricks
  end

end
