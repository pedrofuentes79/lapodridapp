require_relative "../test_helper"

module LaPodrida
  module Tracking
    class RoundTest < LaPodrida::TestCase
      test "initialize with valid params" do
        round = setup_round(player_count: 3, cards_dealt: 5)

        assert_equal player_names(3), round.players
        assert_equal 5, round.cards_dealt
        assert_equal 1, round.starting_position
        assert_equal :bidding, round.phase
        assert_empty round.bids
        assert_empty round.tricks_won
      end

      test "initialize with starting position" do
        round = setup_round(player_count: 3, cards_dealt: 5, starting_position: 2)
        assert_equal 2, round.starting_position
      end

      test "initialize rejects empty players" do
        assert_raises(ArgumentError) do
          Round.new(players: [], cards_dealt: 5)
        end
      end

      test "initialize rejects zero cards" do
        assert_raises(ArgumentError) do
          setup_round(player_count: 2, cards_dealt: 0)
        end
      end

      test "players in order with position 1" do
        round = setup_round(player_count: 4, cards_dealt: 5, starting_position: 1)
        assert_equal %w[A B C D], round.players_in_order
      end

      test "players in order with position 2" do
        round = setup_round(player_count: 4, cards_dealt: 5, starting_position: 2)
        assert_equal %w[B C D A], round.players_in_order
      end

      test "players in order with position 4" do
        round = setup_round(player_count: 4, cards_dealt: 5, starting_position: 4)
        assert_equal %w[D A B C], round.players_in_order
      end

      test "players in order wraps around" do
        round = setup_round(player_count: 3, cards_dealt: 5, starting_position: 5)
        # position 5 % 3 = 2, so starts at index 1 (B)
        assert_equal %w[B C A], round.players_in_order
      end

      test "current bidder follows order" do
        round = setup_round(player_count: 3, cards_dealt: 5, starting_position: 2)

        assert_equal "B", round.current_bidder
        round.place_bid("B", 1)

        assert_equal "C", round.current_bidder
        round.place_bid("C", 2)

        assert_equal "A", round.current_bidder
      end

      test "place bid records bid" do
        round = setup_round(player_count: 2, cards_dealt: 5)
        round.place_bid("A", 3)

        assert_equal({ "A" => 3 }, round.bids)
      end

      test "place bid rejects unknown player" do
        round = setup_round(player_count: 2, cards_dealt: 5)

        assert_raises(ArgumentError) do
          round.place_bid("Unknown", 1)
        end
      end

      test "place bid rejects negative" do
        round = setup_round(player_count: 2, cards_dealt: 5)

        assert_raises(InvalidBid) do
          round.place_bid("A", -1)
        end
      end

      test "place bid rejects exceeding cards dealt" do
        round = setup_round(player_count: 2, cards_dealt: 5)

        assert_raises(InvalidBid) do
          round.place_bid("A", 6)
        end
      end

      test "place bid allows max cards dealt" do
        round = setup_round(player_count: 2, cards_dealt: 5)
        round.place_bid("A", 5)

        assert_equal 5, round.bids["A"]
      end

      test "place bid allows zero" do
        round = setup_round(player_count: 2, cards_dealt: 5)
        round.place_bid("A", 0)

        assert_equal 0, round.bids["A"]
      end

      test "forbidden number nil when not last" do
        round = setup_round(player_count: 3, cards_dealt: 5)
        round.place_bid("A", 2)

        assert_nil round.forbidden_number
      end

      test "forbidden number computed for last bidder" do
        round = setup_round(player_count: 3, cards_dealt: 5)
        round.place_bid("A", 2)
        round.place_bid("B", 1)

        # C is last, forbidden = 5 - 2 - 1 = 2
        assert_equal 2, round.forbidden_number
      end

      test "last bidder cannot bid forbidden number" do
        round = setup_round(player_count: 3, cards_dealt: 5)
        round.place_bid("A", 2)
        round.place_bid("B", 1)

        assert_raises(ForbiddenBidError) do
          round.place_bid("C", 2)
        end
      end

      test "last bidder can bid other numbers" do
        round = setup_round(player_count: 3, cards_dealt: 5)
        round.place_bid("A", 2)
        round.place_bid("B", 1)

        round.place_bid("C", 0)
        assert_equal 0, round.bids["C"]
      end

      test "last bidder helper" do
        round = setup_round(player_count: 3, cards_dealt: 5)

        refute round.last_bidder?("A")
        round.place_bid("A", 1)

        refute round.last_bidder?("B")
        round.place_bid("B", 1)

        assert round.last_bidder?("C")
      end

      test "phase advances to playing after all bids" do
        round = setup_round(player_count: 2, cards_dealt: 5)

        assert round.bidding?
        round.place_bid("A", 2)
        assert round.bidding?
        round.place_bid("B", 1)
        assert round.playing?
      end

      test "cannot bid in playing phase" do
        round = setup_round(player_count: 2, cards_dealt: 5)
        round.place_bid("A", 2)
        round.place_bid("B", 1)

        assert_raises(InvalidPhase) do
          round.place_bid("A", 3)
        end
      end

      test "record tricks in playing phase" do
        round = setup_round(player_count: 2, cards_dealt: 5)
        round.place_bid("A", 2)
        round.place_bid("B", 1)

        round.record_tricks("A", 3)
        assert_equal({ "A" => 3 }, round.tricks_won)
      end

      test "cannot record tricks in bidding phase" do
        round = setup_round(player_count: 2, cards_dealt: 5)

        assert_raises(InvalidPhase) do
          round.record_tricks("A", 3)
        end
      end

      test "record tricks rejects negative" do
        round = setup_round(player_count: 2, cards_dealt: 5)
        round.place_bid("A", 2)
        round.place_bid("B", 1)

        assert_raises(InvalidTrickCount) do
          round.record_tricks("A", -1)
        end
      end

      test "record tricks rejects exceeding cards" do
        round = setup_round(player_count: 2, cards_dealt: 5)
        round.place_bid("A", 2)
        round.place_bid("B", 1)

        assert_raises(InvalidTrickCount) do
          round.record_tricks("A", 6)
        end
      end

      test "phase advances to complete after all tricks" do
        round = setup_round(player_count: 2, cards_dealt: 5)
        round.place_bid("A", 2)
        round.place_bid("B", 1)

        round.record_tricks("A", 3)
        assert round.playing?

        round.record_tricks("B", 2)
        assert round.complete?
      end

      test "points for match" do
        round = setup_round(player_count: 2, cards_dealt: 5)
        round.place_bid("A", 2)
        round.place_bid("B", 1)
        round.record_tricks("A", 2)
        round.record_tricks("B", 3)

        assert_equal 14, round.points_for("A") # 10 + 2*2
        assert_equal 3, round.points_for("B")  # mismatch
      end

      test "points nil before tricks recorded" do
        round = setup_round(player_count: 2, cards_dealt: 5)
        round.place_bid("A", 2)
        round.place_bid("B", 1)

        assert_nil round.points_for("A")
      end

      test "valid round" do
        round = setup_round(player_count: 2, cards_dealt: 5)
        round.place_bid("A", 2)
        round.place_bid("B", 1)
        round.record_tricks("A", 2)
        round.record_tricks("B", 3)

        assert round.valid?
        assert round.complete?
        refute round.invalid?
      end

      test "invalid when tricks dont sum to cards" do
        round = setup_round(player_count: 2, cards_dealt: 5)
        round.place_bid("A", 2)
        round.place_bid("B", 1)
        round.record_tricks("A", 2)
        round.record_tricks("B", 2) # total = 4, should be 5

        refute round.valid?
        assert round.invalid?
      end

      test "total bids and tricks" do
        round = setup_round(player_count: 3, cards_dealt: 5)
        round.place_bid("A", 2)
        round.place_bid("B", 1)
        round.place_bid("C", 0)

        assert_equal 3, round.total_bids

        round.record_tricks("A", 2)
        round.record_tricks("B", 2)
        round.record_tricks("C", 1)

        assert_equal 5, round.total_tricks
      end

      test "to_h and from_h" do
        round = setup_round(player_count: 2, cards_dealt: 5, starting_position: 2)
        round.place_bid("A", 2)
        round.place_bid("B", 1)
        round.record_tricks("A", 3)

        hash = round.to_h
        restored = Round.from_h(hash)

        assert_equal round.players, restored.players
        assert_equal round.cards_dealt, restored.cards_dealt
        assert_equal round.starting_position, restored.starting_position
        assert_equal round.phase, restored.phase
        assert_equal round.bids, restored.bids
        assert_equal round.tricks_won, restored.tricks_won
      end

      test "from_h with string keys" do
        hash = {
          "players" => player_names(2),
          "cards_dealt" => 5,
          "starting_position" => 1,
          "phase" => "playing",
          "bids" => { "A" => 2, "B" => 1 },
          "tricks_won" => {}
        }

        round = Round.from_h(hash)

        assert_equal player_names(2), round.players
        assert_equal :playing, round.phase
        assert_equal({ "A" => 2, "B" => 1 }, round.bids)
      end

      test "place bid returns self" do
        round = setup_round(player_count: 2, cards_dealt: 5)
        result = round.place_bid("A", 2)

        assert_same round, result
      end

      test "record tricks returns self" do
        round = setup_round(player_count: 2, cards_dealt: 5)
        round.place_bid("A", 2)
        round.place_bid("B", 1)

        result = round.record_tricks("A", 3)
        assert_same round, result
      end

      test "correct bid works in any phase" do
        round = setup_round(player_count: 2, cards_dealt: 5)
        round.place_bid("A", 2)
        round.place_bid("B", 1)
        assert round.playing?

        round.correct_bid("A", 4)
        assert_equal 4, round.bids["A"]
      end

      test "correct bid allows forbidden number" do
        round = setup_round(player_count: 3, cards_dealt: 5)
        round.place_bid("A", 2)
        round.place_bid("B", 1)
        round.place_bid("C", 0)

        round.correct_bid("C", 2)
        assert_equal 2, round.bids["C"]
      end

      test "correct bid advances phase when all bids placed" do
        round = setup_round(player_count: 2, cards_dealt: 5)
        assert round.bidding?

        round.correct_bid("A", 2)
        assert round.bidding?

        round.correct_bid("B", 1)
        assert round.playing?
      end

      test "correct tricks works in any phase" do
        round = setup_round(player_count: 2, cards_dealt: 5)
        round.place_bid("A", 2)
        round.place_bid("B", 1)
        round.record_tricks("A", 3)
        round.record_tricks("B", 2)
        assert round.complete?

        round.correct_tricks("A", 2)
        assert_equal 2, round.tricks_won["A"]
      end

      test "correct tricks advances phase when all tricks recorded" do
        round = setup_round(player_count: 2, cards_dealt: 5)
        round.place_bid("A", 2)
        round.place_bid("B", 1)
        assert round.playing?

        round.correct_tricks("A", 3)
        assert round.playing?

        round.correct_tricks("B", 2)
        assert round.complete?
      end
    end
  end
end
