class Game
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_reader :players
    attr_accessor :rounds, :id, :current_round, :started, :leaderboard, :broadcaster

    @@games = {}

    def self.find(id)
        @@games[id]
    end

    def initialize(players = nil, rounds = nil)
      @id = SecureRandom.uuid
      @players = GamePlayers.new(players)
      @leaderboard = Leaderboard.new(self)
      @broadcaster = GameBroadcaster.new(self)

      if valid?
        @@games[@id] = self
        parse_rounds(rounds)
        @strategy = PointCalculationStrategy.new()
      else
        puts errors.full_messages
      end
    end

    def start
        @started = true
    end

    def next_round
        next_round_number = @current_round.round_number + 1
        @current_round = @rounds[next_round_number] || NullRound.new()
        @current_round
    end

    def to_json(options = {})
        {
            id: @id,
            players: @players,
            rounds: @rounds.map { |round_number, round| [ round_number, round.to_json ] }.to_h,
            current_round_number: @current_round.round_number,
            started: @started
        }.to_json(options)
    end

    def update_state(state)
        if state["current_round_number"]
          @current_round = @rounds[state["current_round_number"]]
        end

        state["rounds"].each do |round_number, round_state|
            round_idx = round_number.to_i
            @rounds[round_idx].update_state(round_state)
        end
        @leaderboard.update
        @broadcaster.broadcast_update_game
        true
    end

    def is_current_round(round)
        @current_round.round_number == round.round_number
    end

    def calculate_points(asked_tricks, tricks_made)
        @strategy.calculate_points(asked_tricks, tricks_made)
    end

    private


    def parse_rounds(rounds)
      # TODO: improve rounds format, very undeclarative now
      # current format is "round_number, amount_of_cards"

      return if rounds.nil? || rounds.empty?

      @rounds = rounds.map.with_index do |(round_str, trump), index|
        round_numbers = round_str.split(",").map(&:to_i)
        starting_player = @players[index % @players.length]
        round = Round.new(self, round_numbers.first, round_numbers.last, trump == "trump", starting_player)
        @current_round = round if index == 0 # set current round to the first round

        [ round_numbers.first, round ]
      end.to_h
    end
end
