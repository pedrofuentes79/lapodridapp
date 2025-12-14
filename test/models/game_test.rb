require "test_helper"

# TODO: add tests that show THE REASON why the state is invalid for any given round
class GameTest < ActiveSupport::TestCase
  def setup
    @game = Game.create
    @alice = Player.find_or_create_by(name: "Alice")
    @bob = Player.find_or_create_by(name: "Bob")
    @charlie = Player.find_or_create_by(name: "Charlie")
    @david = Player.find_or_create_by(name: "David")
    @erika = Player.find_or_create_by(name: "Erika")
    @frank = Player.find_or_create_by(name: "Frank")
  end

  test "should create a game" do
    assert @game.persisted?
  end

  test "should have many players through game_participations" do
    @game.game_participations.create(player: @alice, position: 1)
    @game.game_participations.create(player: @bob, position: 2)

    assert_equal 2, @game.players.count
    assert_includes @game.players, @alice
    assert_includes @game.players, @bob
  end

  test "should have many rounds" do
    @game.game_participations.create(player: @alice, position: 1)
    @game.game_participations.create(player: @bob, position: 2)

    round1 = @game.create_next_round(7)
    round2 = @game.create_next_round(6)

    assert_equal 2, @game.rounds.count
    assert_includes @game.rounds, round1
    assert_includes @game.rounds, round2
  end

  test "should destroy associated rounds when game is destroyed" do
    @game.game_participations.create(player: @alice, position: 1)
    @game.game_participations.create(player: @bob, position: 2)

    round = @game.create_next_round(7)
    round_id = round.id

    @game.destroy

    assert_nil Round.find_by(id: round_id)
  end

  test "should raise if trying to make/ask tricks if previous round isn't complete" do
    @game.game_participations.create(player: @alice, position: 1)
    @game.game_participations.create(player: @bob, position: 2)

    round1 = @game.rounds.create(cards_dealt: 7, round_number: 1)
    round2 = @game.rounds.create(cards_dealt: 6, round_number: 2)

    @game.ask_for_tricks(round1, @alice, 2)
    @game.ask_for_tricks(round1, @bob, 3)
    @game.make_tricks(round1, @alice, 3)

    assert !round1.all_players_made_tricks?

    error = assert_raises(RuntimeError) do
      @game.ask_for_tricks(round2, @alice, 2)
    end
    assert_equal "The previous round is invalid. You need to correct it to move on to the next round", error.message

    error = assert_raises(RuntimeError) do
      @game.make_tricks(round2, @alice, 2)
    end
    assert_equal "The previous round is invalid. You need to correct it to move on to the next round", error.message
  end

  test "should allow an invalid round state" do
    @game.game_participations.create(player: @alice, position: 1)
    @game.game_participations.create(player: @bob, position: 2)

    round1 = @game.create_next_round(7)

    # Valid state
    @game.ask_for_tricks(round1, @alice, 2)
    @game.ask_for_tricks(round1, @bob, 3)
    @game.make_tricks(round1, @alice, 3)
    @game.make_tricks(round1, @bob, 4)


    assert_nothing_raised do
      @game.make_tricks(round1, @alice, 2)
      # now we have an invalid state
      assert_not round1.valid_state?
      # now we correct the state adding to bob the trick we removed from alice
      @game.make_tricks(round1, @bob, 5)
    end
  end

  test "should not allow moving on to the next round if the current round is invalid" do
    @game.game_participations.create(player: @alice, position: 1)
    @game.game_participations.create(player: @bob, position: 2)

    round1 = @game.create_next_round(7)
    round2 = @game.create_next_round(6)

    @game.ask_for_tricks(round1, @alice, 2)
    @game.ask_for_tricks(round1, @bob, 3)
    @game.make_tricks(round1, @alice, 3)

    assert_nothing_raised do
      # bob makes 3 tricks. Sum is 6, so round1 is invalid.
      # This does not raise because we're allowing invalid states (for them to be corrected later)
      @game.make_tricks(round1, @bob, 3)
    end

    assert_not round1.valid_state?


    # --- TRY TO MOVE ON TO THE NEXT ROUND ---
    error = assert_raises(RuntimeError) do
      @game.ask_for_tricks(round2, @alice, 2)
    end
    assert_equal "The previous round is invalid. You need to correct it to move on to the next round", error.message

    error = assert_raises(RuntimeError) do
      @game.make_tricks(round2, @alice, 2)
    end
    assert_equal "The previous round is invalid. You need to correct it to move on to the next round", error.message

    # ------------------------------------------

    # --- CORRECT THE STATE ---
    # Now we correct the state by making alice make 4 tricks
    @game.make_tricks(round1, @alice, 4)
    assert round1.valid_state?

    # ------------------------------------------
    # And we can move on to the next round
    assert_nothing_raised do
      @game.ask_for_tricks(round2, @alice, 2)
    end
  end

  # ----- TESTS FOR CREATING THE NEXT ROUND -----
  test "should create next rounds correctly" do
    @game.game_participations.create(player: @alice, position: 1)
    @game.game_participations.create(player: @bob, position: 2)

    round1 = @game.create_next_round(7)
    round2 = @game.create_next_round(6)

    assert_equal 2, @game.rounds.count
    assert_includes @game.rounds, round1
    assert_includes @game.rounds, round2

    assert_equal 1, round1.round_number
    assert_equal 2, round2.round_number
  end

  test "should raise if trying to create a round with a non-sequential round number" do
    @game.game_participations.create(player: @alice, position: 1)
    @game.game_participations.create(player: @bob, position: 2)

    _ = @game.create_next_round(7)

    # manually create a round with a bigger number
    error = assert_raises(RuntimeError) do
      @game.rounds.create(cards_dealt: 6, round_number: 3)
    end
    assert_equal "The round numbers are not sequential", error.message
  end

  test "should raise if trying to create a round when there are gaps in existing rounds" do
    @game.game_participations.create(player: @alice, position: 1)
    @game.game_participations.create(player: @bob, position: 2)

    # Create round 1
    _ = @game.create_next_round(7)

    # Try to create round 3 directly (skipping round 2) - should fail validation
    round3 = Round.new(game: @game, cards_dealt: 6, round_number: 3)
    assert_not round3.valid?
    assert_includes round3.errors[:round_number], "must be sequential. Expected 2, got 3"

    # Create round 2 first, then use update_column to change it to round 3 (bypassing validations)
    round2 = @game.create_next_round(6)
    round2.update_column(:round_number, 3) # Create gap by changing round_number to 3

    # Now try to create round 4 - should fail because round 3 is missing
    round4 = Round.new(game: @game, cards_dealt: 5, round_number: 4)
    assert_not round4.valid?
    assert_includes round4.errors[:round_number], "is not sequential - there are gaps in existing rounds"
  end

  # ----- TESTS FOR THE MAXIMUM NUMBER OF CARDS DEALT -----
  test "should know the maximum number of cards dealt for a game" do
    game1 = Game.create
    game1.game_participations.create(player: @alice, position: 1)
    game1.game_participations.create(player: @bob, position: 2)
    game1.game_participations.create(player: @charlie, position: 3)
    game1.game_participations.create(player: @david, position: 4)

    assert_equal 4, game1.players.count

    # this should not raise. 52 / 4 = 13
    assert_nothing_raised do
      game1.create_next_round(13, has_trump: false)
    end

    # this should raise. 51 / 4 < 13
    assert_raises(RuntimeError) do
      game1.create_next_round(13, has_trump: true)
    end

    # this is ok; 51 / 4 > 12
    assert_nothing_raised do
      game1.create_next_round(12, has_trump: true)
    end

    assert_equal 13, game1.rounds.first.maximum_cards_dealt
    assert_equal 12, game1.rounds.second.maximum_cards_dealt
  end


  # ----- TESTS FOR WINNER CALCULATION -----
  test "should calculate the winner of a game" do
    @game.game_participations.create(player: @alice, position: 1)
    @game.game_participations.create(player: @bob, position: 2)

    round1 = @game.create_next_round(7)
    round2 = @game.create_next_round(6)

    @game.ask_for_tricks(round1, @alice, 2)
    @game.ask_for_tricks(round1, @bob, 4)
    @game.make_tricks(round1, @alice, 2)
    @game.make_tricks(round1, @bob, 5)

    assert_not @game.all_rounds_over?
    assert_nil @game.winner # since game not over yet!

    @game.ask_for_tricks(round2, @alice, 2)
    @game.ask_for_tricks(round2, @bob, 5)
    @game.make_tricks(round2, @alice, 2)
    @game.make_tricks(round2, @bob, 4)

    assert_equal @alice, @game.winner
    assert @game.all_rounds_over?
  end

  # TODO: leaderboard tests...

  # ----- TESTS FOR PLAYER POSITION CALCULATION -----

  test "should advance starting position after the first round" do
    @game.game_participations.create(player: @alice, position: 1)
    @game.game_participations.create(player: @bob, position: 2)
    @game.game_participations.create(player: @charlie, position: 3)
    @game.game_participations.create(player: @david, position: 4)
    @game.game_participations.create(player: @erika, position: 5)
    @game.game_participations.create(player: @frank, position: 6)

    round1 = @game.create_next_round(7)
    round2 = @game.create_next_round(6)
    round3 = @game.create_next_round(5)
    round4 = @game.create_next_round(4)
    round5 = @game.create_next_round(3)
    round6 = @game.create_next_round(2)
    round7 = @game.create_next_round(1)
    round8 = @game.create_next_round(2)
    round9 = @game.create_next_round(3)

    assert_equal 1, round1.starts_at
    assert_equal @alice, round1.starting_player

    assert_equal 2, round2.starts_at
    assert_equal @bob, round2.starting_player

    assert_equal 3, round3.starts_at
    assert_equal @charlie, round3.starting_player

    assert_equal 4, round4.starts_at
    assert_equal @david, round4.starting_player

    assert_equal 5, round5.starts_at
    assert_equal @erika, round5.starting_player

    assert_equal 6, round6.starts_at
    assert_equal @frank, round6.starting_player

    assert_equal 1, round7.starts_at
    assert_equal @alice, round7.starting_player

    assert_equal 2, round8.starts_at
    assert_equal @bob, round8.starting_player

    assert_equal 3, round9.starts_at
    assert_equal @charlie, round9.starting_player

  end

  # ----- TESTS FOR CURRENT ROUND NUMBER CALCULATION -----
  test "should update the current round number when a round is over" do
    @game.game_participations.create(player: @alice, position: 1)
    @game.game_participations.create(player: @bob, position: 2)

    round1 = @game.create_next_round(7)
    round2 = @game.create_next_round(6)
    round3 = @game.create_next_round(5)

    # current round is #1
    assert_equal 1, @game.current_round_number
    assert_equal round1, @game.current_round

    @game.ask_for_tricks(round1, @alice, 2)
    @game.ask_for_tricks(round1, @bob, 4)
    @game.make_tricks(round1, @alice, 2)
    @game.make_tricks(round1, @bob, 5)

    assert_equal 2, @game.current_round_number
    assert_equal round2, @game.current_round

    @game.ask_for_tricks(round2, @alice, 2)
    @game.ask_for_tricks(round2, @bob, 5)
    @game.make_tricks(round2, @alice, 2)

    # Round 2 not complete yet
    assert_equal 2, @game.current_round_number
    assert_equal round2, @game.current_round

    @game.make_tricks(round2, @bob, 4)
    # now it's complete

    assert_equal 3, @game.current_round_number
    assert_equal round3, @game.current_round

    # however, when we edit round 1, current round number should still be 3 (since round 2 is still complete)
    @game.make_tricks(round1, @alice, 3)
    @game.make_tricks(round1, @bob, 4)

    assert_equal 3, @game.current_round_number
    assert_equal round3, @game.current_round

    # now we make round 3 complete
    @game.ask_for_tricks(round3, @alice, 2)
    @game.ask_for_tricks(round3, @bob, 4)
    @game.make_tricks(round3, @alice, 2)
    @game.make_tricks(round3, @bob, 3)

    assert_equal 3, @game.current_round_number
    assert_equal round3, @game.current_round

    assert_equal @alice, @game.winner
  end
end
