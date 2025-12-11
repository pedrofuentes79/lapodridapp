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

  test "should raise if the last player to make tricks doesn't make the total number of tricks" do
    round = @game.rounds.create(cards_dealt: 7, round_number: 0)
    @game.ask_for_tricks(round, @player1, 2)
    @game.ask_for_tricks(round, @player2, 3)
    @game.ask_for_tricks(round, @player3, 1)
    @game.make_tricks(round, @player1, 2)
    @game.make_tricks(round, @player2, 3)
    _ = assert_raises(RuntimeError) do
      @game.make_tricks(round, @player3, 3)
    end
  end

  test "should allow player to overwrite the tricks they asked for" do
    round = @game.rounds.create(cards_dealt: 7, round_number: 0)
    @game.ask_for_tricks(round, @player1, 2)
    @game.ask_for_tricks(round, @player2, 3)
    @game.ask_for_tricks(round, @player3, 1)
    @game.ask_for_tricks(round, @player1, 1)
  end

  test "should allow last player to overwrite the tricks they asked for" do
    round = @game.rounds.create(cards_dealt: 7, round_number: 0)
    @game.ask_for_tricks(round, @player1, 2)
    @game.ask_for_tricks(round, @player2, 3)
    @game.ask_for_tricks(round, @player3, 1)
    @game.ask_for_tricks(round, @player3, 3)
  end
  test "should not allow any player to overwrite the tricks they asked for if they ask for a forbidden number" do
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
end
