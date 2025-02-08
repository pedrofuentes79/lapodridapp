require 'rails_helper'

RSpec.describe Game, type: :model do
    let(:players) { [ 'Pedro', 'Auro', 'Leon' ] }
    let(:rounds) { { [ 1, 4 ] => 'trump', [ 2, 5 ] => 'trump', [ 3, 4 ] => 'trump' } }
    let(:game) { Game.new(players, rounds) }

    describe 'validations' do
      it 'is valid with valid attributes' do
        game = Game.new(players)
        expect(game).to be_valid
      end

      it 'is not valid without players' do
        game = Game.new
        expect(game).not_to be_valid
        expect(game.errors.full_messages).to include("Players can't be blank")
      end

      it 'is not valid with non-string players' do
        game = Game.new([ 1, 2, 3 ])
        expect(game).not_to be_valid
        expect(game.errors.full_messages).to include("Players must all be strings")
      end

      it 'is not valid with empty array of players' do
        game = Game.new([])
        expect(game).not_to be_valid
        expect(game.errors.full_messages).to include("Players can't be blank")
      end

      it 'is not valid with mixed string and non-string players' do
        game = Game.new([ 'Player1', 2, 'Player3' ])
        expect(game).not_to be_valid
        expect(game.errors.full_messages).to include("Players must all be strings")
      end
    end

    describe 'initialization' do
      it 'initializes with players and a starting player' do
        game = Game.new(players)
        expect(game.players).to eq(players)
        expect(game.current_starting_player).to eq('Pedro')
      end

      it 'sets up initial state when valid' do
        game = Game.new(players)
        expect(game.id).not_to be_nil
        expect(game.max_round_number).to eq(0)
        expect(game.started).to be_nil
      end

      it 'does not set up game state when invalid' do
        game = Game.new([ 1, 2, 3 ])  # invalid players
        expect(game.id).not_to be_nil  # ID is always set
        expect(game.rounds).to be_nil
        expect(game.current_round).to be_nil
      end

      it 'generates a unique UUID for each game' do
        game1 = Game.new(players)
        game2 = Game.new(players)
        expect(game1.id).not_to eq(game2.id)
        expect(game1.id).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
      end
    end

    describe 'class methods' do
      it 'can find a game by id' do
        game = Game.new(players)
        expect(Game.find(game.id)).to eq(game)
      end

      it 'returns nil when finding non-existent game' do
        expect(Game.find('non-existent-id')).to be_nil
      end
    end

    xit 'is created also by passing the rounds' do
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

  xit 'allows players to ask for tricks' do
    game.start()
    game.ask_for_tricks('Pedro', 1)
    game.ask_for_tricks('Auro', 2)
    game.ask_for_tricks('Leon', 0)
    expect(game.current_round.asked_tricks).to eq({ 'Pedro' => 1, 'Auro' => 2, 'Leon' => 0 })
  end

  xit 'does not allow last player to ask for tricks if total sum equals amount of cards per round' do
    game.start()
    game.ask_for_tricks('Pedro', 1)
    game.ask_for_tricks('Auro', 2)
    expect { game.ask_for_tricks('Leon', 1) }.to raise_error(ArgumentError)
  end

  xit "does not allow a player to ask for tricks if it is not their turn" do
    game.start()
    game.ask_for_tricks('Pedro', 1)
    expect { game.ask_for_tricks('Leon', 1) }.to raise_error(ArgumentError, "Wrong player turn. Expected Auro, got Leon")
  end

  xit 'advances turn after a player asks for tricks' do
    game.start()
    game.ask_for_tricks('Pedro', 1)
    expect(game.current_round.current_player).to eq('Auro')
  end

  xit 'makes first player current once all players have asked for tricks' do
    game.start()
    game.ask_for_tricks('Pedro', 1)
    game.ask_for_tricks('Auro', 2)
    game.ask_for_tricks('Leon', 0)
    expect(game.current_round.current_player).to eq('Pedro')
  end

  xit 'allows player to register how many tricks they made' do
    game.start()
    game.ask_for_tricks('Pedro', 1)
    game.ask_for_tricks('Auro', 2)
    game.ask_for_tricks('Leon', 0)
    game.register_tricks('Pedro', 1)
    game.register_tricks('Auro', 2)
    game.register_tricks('Leon', 1)
    expect(game.current_round.tricks_made).to eq({ 'Pedro' => 1, 'Auro' => 2, 'Leon' => 1 })
  end

  xit 'does not allow a player to register more tricks than the amount of cards per round' do
    game.start()
    game.ask_for_tricks('Pedro', 1)
    game.ask_for_tricks('Auro', 2)
    game.ask_for_tricks('Leon', 0)
    expect { game.register_tricks('Pedro', 5) }.to raise_error(ArgumentError, "Invalid amount of tricks made by that player")
  end

  xit "does not allow a player to register less than 0 tricks" do
    game.start()
    game.ask_for_tricks('Pedro', 1)
    game.ask_for_tricks('Auro', 2)
    game.ask_for_tricks('Leon', 0)
    expect { game.register_tricks('Pedro', -1) }.to raise_error(ArgumentError, "Invalid amount of tricks made by that player")
  end

  xit "does not allow a player to register tricks if all players have not asked for tricks" do
    game.start()
    game.ask_for_tricks('Pedro', 1)
    game.ask_for_tricks('Auro', 2)
    expect { game.register_tricks('Pedro', 1) }.to raise_error(ArgumentError, "Cannot register tricks if all players have not asked for tricks")
  end

  xit "know how many points each player had per round" do
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
