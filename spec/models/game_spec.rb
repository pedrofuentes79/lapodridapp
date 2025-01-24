require 'rails_helper'

RSpec.describe Game, type: :model do
    let(:players) { [ 'Pedro', 'Auro', 'Leon' ] }
    let(:rounds) { { [ 1, 4 ] => 'trump', [ 2, 5 ] => 'trump', [ 3, 4 ] => 'trump' } }
    let(:game) { Game.new(players, rounds) }
    # region INITIALIZATION TESTS
    it 'initializes with players and a starting player' do
      game = Game.new(players)
      expect(game.players).to eq(players)
      expect(game.current_starting_player).to eq('Pedro')
    end

    it 'throws error if no players are passed' do
      expect { Game.new }.to raise_error(ArgumentError)
    end

    it 'cannot be created with invalid players' do
      expect { Game.new([ 1, 2 ]) }.to raise_error(ArgumentError)
    end

    it 'is created also by passing the rounds' do
      round1 = game.next_round
      expect(round1.round_number).to eq(1)
      expect(round1.amount_of_cards).to eq(4)
      expect(round1.is_trump?).to be true

      round2 = game.next_round
      expect(round2.round_number).to eq(2)
      expect(round2.amount_of_cards).to eq(5)
      expect(round2.is_trump?).to be true

      round3 = game.next_round
      expect(round3.round_number).to eq(3)
      expect(round3.amount_of_cards).to eq(4)
      expect(round3.is_trump?).to be true

      expect(game.next_round).to be_nil
    end

  # endregion

  it 'allows players to ask for tricks' do
    game.start()
    game.ask_for_tricks('Pedro', 1)
    game.ask_for_tricks('Auro', 2)
    game.ask_for_tricks('Leon', 0)
    expect(game.current_round.asked_tricks).to eq({ 'Pedro' => 1, 'Auro' => 2, 'Leon' => 0 })
  end

  it 'does not allow last player to ask for tricks if total sum equals amount of cards per round' do
    game.start()
    game.ask_for_tricks('Pedro', 1)
    game.ask_for_tricks('Auro', 2)
    expect { game.ask_for_tricks('Leon', 1) }.to raise_error(ArgumentError)
  end

  it "does not allow a player to ask for tricks if it is not their turn" do
    game.start()
    game.ask_for_tricks('Pedro', 1)
    expect { game.ask_for_tricks('Leon', 1) }.to raise_error(ArgumentError, "Wrong player turn. Expected Auro, got Leon")
  end

  it 'advances turn after a player asks for tricks' do
    game.start()
    game.ask_for_tricks('Pedro', 1)
    expect(game.current_round.current_player).to eq('Auro')
  end

  it 'makes first player current once all players have asked for tricks' do
    game.start()
    game.ask_for_tricks('Pedro', 1)
    game.ask_for_tricks('Auro', 2)
    game.ask_for_tricks('Leon', 0)
    expect(game.current_round.current_player).to eq('Pedro')
  end

  it 'allows player to register how many tricks they made' do
    game.start()
    game.ask_for_tricks('Pedro', 1)
    game.ask_for_tricks('Auro', 2)
    game.ask_for_tricks('Leon', 0)
    game.register_tricks('Pedro', 1)
    game.register_tricks('Auro', 2)
    game.register_tricks('Leon', 1)
    expect(game.current_round.tricks_made).to eq({ 'Pedro' => 1, 'Auro' => 2, 'Leon' => 1 })
  end

  it 'does not allow a player to register more tricks than the amount of cards per round' do
    game.start()
    game.ask_for_tricks('Pedro', 1)
    game.ask_for_tricks('Auro', 2)
    game.ask_for_tricks('Leon', 0)
    expect { game.register_tricks('Pedro', 5) }.to raise_error(ArgumentError, "Invalid amount of tricks made by that player")
  end

  it "does not allow a player to register less than 0 tricks" do
    game.start()
    game.ask_for_tricks('Pedro', 1)
    game.ask_for_tricks('Auro', 2)
    game.ask_for_tricks('Leon', 0)
    expect { game.register_tricks('Pedro', -1) }.to raise_error(ArgumentError, "Invalid amount of tricks made by that player")
  end

  it "does not allow a player to register tricks if all players have not asked for tricks" do
    game.start()
    game.ask_for_tricks('Pedro', 1)
    game.ask_for_tricks('Auro', 2)
    expect { game.register_tricks('Pedro', 1) }.to raise_error(ArgumentError, "Cannot register tricks if all players have not asked for tricks")
  end

  it "know how many points each player had per round" do
    game.start()
    game.ask_for_tricks('Pedro', 1)
    game.ask_for_tricks('Auro', 2)
    game.ask_for_tricks('Leon', 0)
    game.register_tricks('Pedro', 1)
    game.register_tricks('Auro', 2)
    game.register_tricks('Leon', 1)
    expect(game.current_round.points).to eq({ 'Pedro' => 12, 'Auro' => 14, 'Leon' => 1 })
  end


end
