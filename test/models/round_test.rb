require "test_helper"

class RoundTest < ActiveSupport::TestCase
  def setup
    @players = ['Pedro', 'Auro', 'Leon']
    @game = Game.new(@players)
    @round = Round.new(@game, 1, 4, true, 'Pedro')
  end

  test "initializes with correct attributes" do
    assert_equal 1, @round.round_number
    assert_equal 4, @round.amount_of_cards
    assert_equal 'Pedro', @round.starting_player
    assert_equal 'Pedro', @round.current_player
    assert_equal 0, @round.amount_of_asked_tricks
    assert @round.is_trump?
  end

  test "tracks asked tricks correctly" do
    @round.ask_for_tricks('Pedro', 2)
    assert_equal 2, @round.amount_of_asked_tricks
    assert_equal 2, @round.total_tricks_asked
    assert_equal 'Auro', @round.current_player
  end

  test "validates player turn" do
    error = assert_raises(ArgumentError) do
      @round.ask_for_tricks('Auro', 1)
    end
    assert_equal "Wrong player turn. Expected Pedro, got Auro", error.message
  end

  test "validates asked tricks amount" do
    error = assert_raises(ArgumentError) do
      @round.ask_for_tricks('Pedro', 5)
    end
    assert_equal "Total asked tricks cannot surpass number of cards in the round", error.message
  end

  test "prevents last player from asking tricks that sum to total" do
    @round.ask_for_tricks('Pedro', 1)
    @round.ask_for_tricks('Auro', 2)
    
    error = assert_raises(ArgumentError) do
      @round.ask_for_tricks('Leon', 1)
    end
    assert_equal "Last player cannot ask for tricks if total sum equals amount of cards per round", error.message
  end

  test "requires all players to ask for tricks before registering" do
    error = assert_raises(ArgumentError) do
      @round.register_tricks('Pedro', 1)
    end
    assert_equal "Not all players have asked for tricks", error.message
  end

  test "validates tricks made amount" do
    @round.ask_for_tricks('Pedro', 1)
    @round.ask_for_tricks('Auro', 2)
    @round.ask_for_tricks('Leon', 0)

    error = assert_raises(ArgumentError) do
      @round.register_tricks('Pedro', 5)
    end
    assert_equal "Invalid number of tricks made", error.message
  end

  test "calculates points correctly after all tricks registered" do
    @round.ask_for_tricks('Pedro', 1)
    @round.ask_for_tricks('Auro', 2)
    @round.ask_for_tricks('Leon', 1)
    
    @round.register_tricks('Pedro', 1)
    @round.register_tricks('Auro', 2)
    @round.register_tricks('Leon', 1)

    expected_points = {
      'Pedro' => 12, # 10 + 1*2 for exact match
      'Auro' => 14,  # 10 + 2*2 for exact match
      'Leon' => 12   # 10 + 1*2 for exact match
    }
    assert_equal expected_points, @round.points
  end

  test "serializes to json correctly" do
    expected_json = {
      round_number: 1,
      amount_of_cards: 4,
      current_player: 'Pedro',
      asked_tricks: {'Pedro' => nil, 'Auro' => nil, 'Leon' => nil},
      tricks_made: {'Pedro' => nil, 'Auro' => nil, 'Leon' => nil},
      points: {},
      starting_player: 'Pedro'
    }
    assert_equal expected_json, @round.to_json
  end

  test "updates state correctly" do
    state = {
      'asked_tricks' => {'Pedro' => 1, 'Auro' => 2, 'Leon' => 1},
      'tricks_made' => {'Pedro' => 1, 'Auro' => 2, 'Leon' => 1},
      'points' => {'Pedro' => 12, 'Auro' => 14, 'Leon' => 12}
    }
    
    @round.update_state(state)
    
    assert_equal state['asked_tricks'], @round.asked_tricks
    assert_equal state['tricks_made'], @round.tricks_made
    assert_equal state['points'], @round.points
  end
end 