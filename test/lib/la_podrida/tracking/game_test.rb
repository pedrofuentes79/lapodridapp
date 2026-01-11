require_relative "../test_helper"

module LaPodrida
  module Tracking
    class GameTest < LaPodrida::TestCase
      test "initialize with players" do
        game = setup_game(player_count: 4)

        assert_equal player_names(4), game.players
        assert_empty game.rounds
      end

      test "initialize rejects single player" do
        assert_raises(ArgumentError) do
          Game.new(players: %w[A])
        end
      end

      test "initialize rejects empty players" do
        assert_raises(ArgumentError) do
          Game.new(players: [])
        end
      end

      test "max cards per player with trump" do
        game = setup_game(player_count: 4)
        # 51 cards / 4 players = 12
        assert_equal 12, game.max_cards_per_player(has_trump: true)
      end

      test "max cards per player without trump" do
        game = setup_game(player_count: 4)
        # 52 cards / 4 players = 13
        assert_equal 13, game.max_cards_per_player(has_trump: false)
      end

      test "max cards with different player counts" do
        assert_equal 25, setup_game(player_count: 2).max_cards_per_player(has_trump: true)
        assert_equal 17, setup_game(player_count: 3).max_cards_per_player(has_trump: true)
        assert_equal 10, setup_game(player_count: 5).max_cards_per_player(has_trump: true)
      end

      test "create round" do
        game = setup_game(player_count: 4)
        round = game.create_round(cards_dealt: 5)

        assert_equal 1, game.rounds.size
        assert_equal 5, round.cards_dealt
        assert_equal player_names(4), round.players
      end

      test "create round rejects zero cards" do
        game = setup_game(player_count: 4)

        assert_raises(ArgumentError) do
          game.create_round(cards_dealt: 0)
        end
      end

      test "create round rejects exceeding max" do
        game = setup_game(player_count: 4)

        assert_raises(ArgumentError) do
          game.create_round(cards_dealt: 13) # max is 12 with trump
        end
      end

      test "create round allows max without trump" do
        game = setup_game(player_count: 4)
        round = game.create_round(cards_dealt: 13, has_trump: false)

        assert_equal 13, round.cards_dealt
      end

      test "starting position rotates" do
        game = setup_game(player_count: 4)

        r1 = game.create_round(cards_dealt: 5)
        assert_equal 1, r1.starting_position

        r2 = game.create_round(cards_dealt: 5)
        assert_equal 2, r2.starting_position

        r3 = game.create_round(cards_dealt: 5)
        assert_equal 3, r3.starting_position

        r4 = game.create_round(cards_dealt: 5)
        assert_equal 4, r4.starting_position

        r5 = game.create_round(cards_dealt: 5)
        assert_equal 1, r5.starting_position # wraps
      end

      test "current round is first incomplete" do
        game = setup_game(player_count: 2)
        r1 = game.create_round(cards_dealt: 5)
        game.create_round(cards_dealt: 5)

        assert_same r1, game.current_round
      end

      test "current round advances when complete" do
        game = setup_game(player_count: 2)
        r1 = game.create_round(cards_dealt: 5)
        r2 = game.create_round(cards_dealt: 5)

        r1.place_bid("A", 2)
        r1.place_bid("B", 1)
        r1.record_tricks("A", 2)
        r1.record_tricks("B", 3)

        assert_same r2, game.current_round
      end

      test "current round number" do
        game = setup_game(player_count: 2)

        assert_equal 1, game.current_round_number

        r1 = game.create_round(cards_dealt: 5)
        assert_equal 1, game.current_round_number

        r1.place_bid("A", 2)
        r1.place_bid("B", 1)
        r1.record_tricks("A", 2)
        r1.record_tricks("B", 3)

        game.create_round(cards_dealt: 5)
        assert_equal 2, game.current_round_number
      end

      test "points for player across rounds" do
        game = setup_game(player_count: 2)

        r1 = game.create_round(cards_dealt: 5)
        r1.place_bid("A", 2).place_bid("B", 1)
        r1.record_tricks("A", 2).record_tricks("B", 3)
        # A: 10 + 4 = 14, B: 3

        r2 = game.create_round(cards_dealt: 3)
        r2.place_bid("A", 1).place_bid("B", 0)
        r2.record_tricks("A", 1).record_tricks("B", 2)
        # A: 10 + 2 = 12, B: 2

        assert_equal 26, game.points_for("A")
        assert_equal 5, game.points_for("B")
      end

      test "scores returns all players" do
        game = setup_game(player_count: 3)
        r1 = game.create_round(cards_dealt: 5)
        r1.place_bid("A", 2).place_bid("B", 1).place_bid("C", 0)
        r1.record_tricks("A", 2).record_tricks("B", 3).record_tricks("C", 0)

        scores = game.scores

        assert_equal 14, scores["A"]
        assert_equal 3, scores["B"]
        assert_equal 10, scores["C"]
      end

      test "winner returns nil when not complete" do
        game = setup_game(player_count: 2)
        game.create_round(cards_dealt: 5)

        assert_nil game.winner
      end

      test "winner returns highest scorer" do
        game = setup_game(player_count: 2)
        r1 = game.create_round(cards_dealt: 5)
        r1.place_bid("A", 2).place_bid("B", 1)
        r1.record_tricks("A", 2).record_tricks("B", 3)

        assert_equal "A", game.winner
      end

      test "complete when all rounds complete" do
        game = setup_game(player_count: 2)
        r1 = game.create_round(cards_dealt: 5)
        r1.place_bid("A", 2).place_bid("B", 1)
        r1.record_tricks("A", 2).record_tricks("B", 3)

        assert game.complete?
      end

      test "not complete when no rounds" do
        game = setup_game(player_count: 2)
        refute game.complete?
      end

      test "not complete with incomplete round" do
        game = setup_game(player_count: 2)
        r1 = game.create_round(cards_dealt: 5)
        r1.place_bid("A", 2)

        refute game.complete?
      end

      test "valid when all rounds valid" do
        game = setup_game(player_count: 2)
        r1 = game.create_round(cards_dealt: 5)
        r1.place_bid("A", 2).place_bid("B", 1)
        r1.record_tricks("A", 2).record_tricks("B", 3)

        assert game.valid?
      end

      test "not valid with invalid round" do
        game = setup_game(player_count: 2)
        r1 = game.create_round(cards_dealt: 5)
        r1.place_bid("A", 2).place_bid("B", 1)
        r1.record_tricks("A", 2).record_tricks("B", 2) # sum = 4, not 5

        refute game.valid?
      end

      test "to_h and from_h" do
        game = setup_game(player_count: 3)
        r1 = game.create_round(cards_dealt: 5)
        r1.place_bid("A", 2).place_bid("B", 1).place_bid("C", 0)
        r1.record_tricks("A", 2).record_tricks("B", 3).record_tricks("C", 0)

        game.create_round(cards_dealt: 3)

        hash = game.to_h
        restored = Game.from_h(hash)

        assert_equal game.players, restored.players
        assert_equal game.rounds.size, restored.rounds.size
        assert_equal game.rounds.first.bids, restored.rounds.first.bids
        assert_equal game.scores, restored.scores
      end

      test "from_h with string keys" do
        hash = {
          "players" => player_names(2),
          "rounds" => [
            {
              "players" => player_names(2),
              "cards_dealt" => 5,
              "starting_position" => 1,
              "phase" => "complete",
              "bids" => { "A" => 2, "B" => 1 },
              "tricks_won" => { "A" => 2, "B" => 3 }
            }
          ]
        }

        game = Game.from_h(hash)

        assert_equal player_names(2), game.players
        assert_equal 1, game.rounds.size
        assert game.complete?
      end

      test "full game flow" do
        game = setup_game(player_count: 3)

        # Round 1: 5 cards, A starts
        r1 = game.create_round(cards_dealt: 5)
        assert_equal "A", r1.current_bidder

        r1.place_bid("A", 2)
        r1.place_bid("B", 1)
        # C is last, forbidden = 5 - 2 - 1 = 2
        assert_equal 2, r1.forbidden_number
        r1.place_bid("C", 1)

        assert r1.playing?

        r1.record_tricks("A", 2)
        r1.record_tricks("B", 2)
        r1.record_tricks("C", 1)

        assert r1.complete?
        assert r1.valid?

        # Round 2: 3 cards, B starts
        r2 = game.create_round(cards_dealt: 3)
        assert_equal 2, r2.starting_position
        assert_equal %w[B C A], r2.players_in_order

        r2.place_bid("B", 1)
        r2.place_bid("C", 0)
        r2.place_bid("A", 1)

        r2.record_tricks("B", 1)
        r2.record_tricks("C", 1)
        r2.record_tricks("A", 1)

        assert game.complete?

        # Final scores
        # A: 14 (r1 match) + 12 (r2 match) = 26
        # B: 2 (r1 mismatch) + 12 (r2 match) = 14
        # C: 12 (r1 match) + 1 (r2 mismatch) = 13

        assert_equal 26, game.points_for("A")
        assert_equal 14, game.points_for("B")
        assert_equal 13, game.points_for("C")
        assert_equal "A", game.winner
      end
    end
  end
end
