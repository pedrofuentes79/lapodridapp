require "test_helper"

# TODO: move this to minitest

class RoundTest < ActiveSupport::TestCase
  def setup
    @players = [ "Pedro", "Auro", "Leon" ]
    @game = Game.new(@players)
    @round = Round.new(@game, 1, 4, true, "Pedro")
  end

  test "initializes with correct attributes" do
    assert_equal 1, @round.round_number
    assert_equal 4, @round.amount_of_cards
    assert_equal "Pedro", @round.starting_player
    assert_equal 0, @round.total_tricks_asked
    assert @round.is_trump?
  end

  test "tracks asked tricks correctly" do
    @round.update_state({
      "asked_tricks" => { "Pedro" => 2 }
    })
    assert_equal 2, @round.total_tricks_asked
  end


  test "validates asked tricks amount" do
    error = assert_raises(ArgumentError) do
      @round.update_state({
        "asked_tricks" => { "Pedro" => 5 }
      })
    end
    assert_equal "Total asked tricks cannot surpass number of cards in the round", error.message
  end

  test "prevents last player from asking tricks that sum to total" do
    @round.update_state({
      "asked_tricks" => { "Pedro" => 1, "Auro" => 2 }
    })

    error = assert_raises(ArgumentError) do
      @round.update_state({
        "asked_tricks" => { "Pedro" => 1, "Auro" => 2, "Leon" => 1 }
      })
    end
    assert_equal "Last player cannot ask for tricks if total sum equals amount of cards per round", error.message
  end

  test "requires all players to ask for tricks before registering" do
    error = assert_raises(ArgumentError) do
      @round.update_state({
        "tricks_made" => { "Pedro" => 1, "Auro" => 2 }
      })
    end
    assert_equal "Not all players have asked for tricks", error.message
  end

  test "player cannot make more tricks than cards in the round" do
    error = assert_raises(ArgumentError) do
      @round.update_state({
        "asked_tricks" => { "Pedro" => 1, "Auro" => 2, "Leon" => 0 },
        "tricks_made" => { "Pedro" => 5 }
      })
    end
    assert_equal "Total tricks made cannot surpass number of cards in the round", error.message
  end

  test "calculates points correctly after all tricks registered" do
    @round.update_state({
      "asked_tricks" => { "Pedro" => 1, "Auro" => 2, "Leon" => 0 },
      "tricks_made" => { "Pedro" => 1, "Auro" => 2, "Leon" => 1 }
    })

    expected_points = {
      "Pedro" => 12,
      "Auro" => 14,
      "Leon" => 1
    }
    assert_equal expected_points, @round.points
  end

  test "serializes to json correctly" do
    expected_json = {
      round_number: 1,
      amount_of_cards: 4,
      asked_tricks: { "Pedro" => nil, "Auro" => nil, "Leon" => nil },
      tricks_made: { "Pedro" => nil, "Auro" => nil, "Leon" => nil },
      points: { "Pedro" => 0, "Auro" => 0, "Leon" => 0 },
      starting_player: "Pedro"
    }
    assert_equal expected_json, @round.to_json
  end

  test "updates state correctly" do
    state = {
      "asked_tricks" => { "Pedro" => 1, "Auro" => 2, "Leon" => 0 },
      "tricks_made" => { "Pedro" => 1, "Auro" => 2, "Leon" => 1 },
      "points" => { "Pedro" => 12, "Auro" => 14, "Leon" => 1 }
    }

    @round.update_state(state)

    assert_equal state["asked_tricks"], @round.asked_tricks
    assert_equal state["tricks_made"], @round.tricks_made
    assert_equal state["points"], @round.points
  end
end
