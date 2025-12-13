require "test_helper"

# TODO: add tests that show THE REASON why the state is invalid for any given round
class GameTest < ActiveSupport::TestCase
  def setup
    @game = Game.create
    @alice = Player.create(name: "Alice")
    @bob = Player.create(name: "Bob")
    @charlie = Player.create(name: "Charlie")
    @david = Player.create(name: "David")
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

    round1 = @game.rounds.create(cards_dealt: 7, round_number: 0)
    round2 = @game.rounds.create(cards_dealt: 6, round_number: 1)

    @game.ask_for_tricks(round1, @alice, 2)
    @game.ask_for_tricks(round1, @bob, 3)
    @game.make_tricks(round1, @alice, 3)

    assert !round1.all_players_made_tricks?
    assert !@game.all_players_made_tricks_in_previous_rounds?(round2)

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

    round1 = @game.rounds.create(cards_dealt: 7, round_number: 0)

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

    round1 = @game.rounds.create(cards_dealt: 7, round_number: 0)
    round2 = @game.rounds.create(cards_dealt: 6, round_number: 1)

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

    assert_equal 0, round1.round_number
    assert_equal 1, round2.round_number
  end

  test "should raise if trying to create a round with a non-sequential round number" do
    @game.game_participations.create(player: @alice, position: 1)
    @game.game_participations.create(player: @bob, position: 2)

    _ = @game.create_next_round(7)

    # manually create a round with a bigger number
    error = assert_raises(RuntimeError) do
      @game.rounds.create(cards_dealt: 6, round_number: 2)
    end
    assert_equal "The round numbers are not sequential", error.message
  end

  test "should raise if trying to create a round when there are gaps in existing rounds" do
    @game.game_participations.create(player: @alice, position: 1)
    @game.game_participations.create(player: @bob, position: 2)

    # Create round 0
    _ = @game.create_next_round(7)

    # Try to create round 2 directly (skipping round 1) - should fail validation
    round2 = Round.new(game: @game, cards_dealt: 6, round_number: 2)
    assert_not round2.valid?
    assert_includes round2.errors[:round_number], "must be sequential. Expected 1, got 2"

    # Create round 1 first, then use update_column to change it to round 2 (bypassing validations)
    round1 = @game.create_next_round(6)
    round1.update_column(:round_number, 2) # Create gap by changing round_number to 2

    # Now try to create round 3 - should fail because round 1 is missing
    round3 = Round.new(game: @game, cards_dealt: 5, round_number: 3)
    assert_not round3.valid?
    assert_includes round3.errors[:round_number], "is not sequential - there are gaps in existing rounds"
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
      game1.create_next_round(13, has_trump: true)
    end

    # this should raise. 51 / 4 < 13
    assert_raises(RuntimeError) do
      game1.create_next_round(13, has_trump: false)
    end

    # this is ok; 51 / 4 > 12
    assert_nothing_raised do
      game1.create_next_round(12, has_trump: false)
    end

    assert_equal 13, game1.rounds.first.maximum_cards_dealt
    assert_equal 12, game1.rounds.second.maximum_cards_dealt

    # game2 = Game.create
    # game2.game_participations.create(player: @alice, position: 1)
    # game2.game_participations.create(player: @bob, position: 2)
    # game2.game_participations.create(player: @charlie, position: 3)
    # game2.game_participations.create(player: @david, position: 4)
    # game2.game_participations.create(player: @emma, position: 5)
  end
end
