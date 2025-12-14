require "test_helper"

class BidTest < ActiveSupport::TestCase
  def setup
    @game = Game.create
    @player1 = Player.find_or_create_by(name: "Alice")
    @player2 = Player.find_or_create_by(name: "Bob")
    @game.game_participations.create(player: @player1, position: 1)
    @game.game_participations.create(player: @player2, position: 2)
    @round = @game.rounds.create(cards_dealt: 7, round_number: 1)
  end

  # NOTE: these tests use `update` instead of `player_asks_for_tricks` and `player_makes_tricks`
  # because they're intended to test the Bid model itself.

  test "should belong to a round and player" do
    # Bid is already created by the after_create callback
    bid = @round.bids.find_by(player: @player1)

    assert_equal @round, bid.round
    assert_equal @player1, bid.player
  end

  test "should enforce uniqueness of player per round" do
    # Bids are already created by the after_create callback
    # Try to create a duplicate bid for a player that already has one
    duplicate_bid = @round.bids.build(player: @player1, predicted_tricks: 2)

    assert_not duplicate_bid.valid?
    assert_includes duplicate_bid.errors[:player_id], "has already been taken"
  end

  test "should calculate points correctly" do
    bid = @round.bids.find_by(player: @player1)
    assert_nil bid.points

    bid.update(predicted_tricks: 3, actual_tricks: 3)
    assert_equal 16, bid.points

    bid.update(predicted_tricks: 3, actual_tricks: 2)
    assert_equal 2, bid.points
  end
  test "should raise if invalid format for predicted_tricks or actual_tricks" do
    bid = @round.bids.find_by(player: @player1)
    bid.update(predicted_tricks: -1)
    assert_not bid.valid?
    assert_includes bid.errors[:predicted_tricks], "must be greater than or equal to 0"

    bid.update(actual_tricks: -1)
    assert_not bid.valid?
    assert_includes bid.errors[:actual_tricks], "must be greater than or equal to 0"

    bid.update(predicted_tricks: 8)
    assert_not bid.valid?
  end
  test "should raise if predicted_tricks/asked_for_tricks is greater than the number of cards dealt" do
    bid = @round.bids.find_by(player: @player1)
    bid.update(predicted_tricks: 8)
    assert_not bid.valid?
    assert_includes bid.errors[:predicted_tricks], "must be less than or equal to #{@round.cards_dealt}"

    bid.update(actual_tricks: 8)
    assert_not bid.valid?
    assert_includes bid.errors[:actual_tricks], "must be less than or equal to #{@round.cards_dealt}"
  end
end
