require_relative "../test_helper"

module LaPodrida
  module Core
    class ForbiddenBidTest < LaPodrida::TestCase
      test "forbidden number when not last bidder" do
        # 3 of 4 players haven't bid yet - no forbidden number
        assert_nil ForbiddenBid.forbidden_number(
          cards_dealt: 5,
          bids: {"A" => 2},
          player_count: 4
        )
      end

      test "forbidden number when last bidder" do
        # 3 players bid, 4th is last: can't bid (5 - 2 - 1 - 1) = 1
        bids = {"A" => 2, "B" => 1, "C" => 1}
        assert_equal 1, ForbiddenBid.forbidden_number(
          cards_dealt: 5,
          bids:,
          player_count: 4
        )
      end

      test "forbidden number can be zero" do
        # If others bid all the cards, forbidden is 0
        bids = {"A" => 3, "B" => 2}
        assert_equal 0, ForbiddenBid.forbidden_number(
          cards_dealt: 5,
          bids:,
          player_count: 3
        )
      end

      test "forbidden number nil when overbid" do
        # If others overbid, no forbidden number (any bid is valid)
        bids = {"A" => 4, "B" => 3}
        assert_nil ForbiddenBid.forbidden_number(
          cards_dealt: 5,
          bids:,
          player_count: 3
        )
      end

      test "forbidden returns true when bid matches" do
        bids = {"A" => 2, "B" => 1, "C" => 1}
        assert ForbiddenBid.forbidden?(
          cards_dealt: 5,
          bids:,
          player_count: 4,
          new_bid: 1
        )
      end

      test "forbidden returns false when bid differs" do
        bids = {"A" => 2, "B" => 1, "C" => 1}
        refute ForbiddenBid.forbidden?(
          cards_dealt: 5,
          bids:,
          player_count: 4,
          new_bid: 0
        )
      end

      test "forbidden returns false when not last bidder" do
        bids = {"A" => 2}
        refute ForbiddenBid.forbidden?(
          cards_dealt: 5,
          bids:,
          player_count: 4,
          new_bid: 3  # would be forbidden if last
        )
      end

      test "forbidden with empty bids" do
        assert_nil ForbiddenBid.forbidden_number(
          cards_dealt: 5,
          bids: {},
          player_count: 4
        )
      end

      test "forbidden with two players" do
        bids = {"A" => 3}
        assert_equal 2, ForbiddenBid.forbidden_number(
          cards_dealt: 5,
          bids:,
          player_count: 2
        )
      end
    end
  end
end
