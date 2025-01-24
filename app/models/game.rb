require_relative 'strategy'

class Game
    attr_reader :players, :current_starting_player, :rounds, :id

    @@games = {}
  
    def initialize(players = nil, rounds = {})
      raise ArgumentError, "No players provided" unless players
      raise ArgumentError, "Invalid players" unless players.all? { |p| p.is_a?(String) }

      @id = SecureRandom.uuid
      @players = players
      @current_starting_player = players.first
      @current_round_number = 0

      parse_rounds(rounds)

      @strategy = PointCalculationStrategy.new()
    end

    def start
        next_round
    end

    def self.find(id)
        @@games[id]
    end

    def ask_for_tricks(player, tricks)
        current_round.ask_for_tricks(player, tricks)
    end

    def register_tricks(player, tricks)
        current_round.register_tricks(player, tricks)
    end

    def calculate_points(asked_tricks, tricks_made)
        @strategy.calculate_points(asked_tricks, tricks_made)
    end


    def next_round
        @current_round_number += 1
        return nil if @current_round_number > @max_round_number
        
        current_round
    end

    def current_round
        @rounds[@current_round_number]
    end

    def next_player_to(player)
        current_index = @players.index(player)
        next_player = @players[(current_index + 1) % @players.length]
        next_player
    end

    private

    def parse_rounds(rounds)
        if rounds.nil? || rounds.empty?
            @rounds = {}
            @max_round_number = 0
            return
        end
        
        @rounds = rounds.map { |round, trump| 
            # HARDCODED START PLAYER, FIX LATER
            [round.first, Round.new(self, round.first, round.last, trump == 'trump', 'Pedro')] 
        }.to_h
        @max_round_number = @rounds.keys.max
    end
end