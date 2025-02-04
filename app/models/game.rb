class Game
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :players, :current_starting_player, :rounds, :id, :max_round_number, :current_round, :started

    validates :players, presence: true
    validate :validate_players_format

    @@games = {}

    # Class methods
    def self.find(id)
        @@games[id]
    end

    def self.all
        @@games.values
    end

    # Public instance methods
    def initialize(players = nil, rounds = {})
      @id = SecureRandom.uuid
      @players = players
      @current_starting_player = players&.first
      @max_round_number = 0

      if valid?
        @@games[@id] = self
        parse_rounds(rounds)
        @strategy = PointCalculationStrategy.new()
      end
    end

    def start
        puts "Game started with id #{@id}"
        @started = true
    end

    def ask_for_tricks(player, tricks)
        @current_round.ask_for_tricks(player, tricks)
    end

    def register_tricks(player, tricks)
        @current_round.register_tricks(player, tricks)
    end

    def next_round
        next_round_number = @current_round.round_number + 1
        @current_round = @rounds[next_round_number]
        @current_round = NullRound.new() if @current_round.nil?
        @current_round
    end

    def next_player_to(player, offset)
        current_index = @players.index(player)
        @players[(current_index + offset) % @players.length]
    end

    def leaderboard
        total_points = Hash.new(0)
        @rounds.each_value do |round|
            round.points.each do |player, points|
                total_points[player] += points
            end
        end
        total_points.sort_by { |player, points| -points }.to_h
    end

    # TODO: check if this is generating valid json?? the frontend is not receiving it right...
    def to_json
        {
            id: @id,
            players: @players,
            current_starting_player: @current_starting_player,
            rounds: @rounds.map { |round_number, round| [ round_number, round.to_json ] }.to_h,
            current_round_number: @current_round.round_number,
            started: @started
        }.to_json
    end

    def update_state(state)
        @current_starting_player = state["current_starting_player"]
        @current_round = @rounds[state["current_round_number"]]
        @started = state["started"]
        @rounds.each do |round_number, round|
            round.update_state(state["rounds"][round_number.to_s])
        end
    end

    def is_current_round(round)
        @current_round.round_number == round.round_number
    end

    def calculate_points(asked_tricks, tricks_made)
        @strategy.calculate_points(asked_tricks, tricks_made)
    end

    def total_tricks_asked
        current_round.total_tricks_asked if current_round
    end

    private

    def validate_players_format
      return if players.nil?

      unless players.all? { |p| p.is_a?(String) }
        errors.add(:players, "must all be strings")
      end
    end

    def parse_rounds(rounds)
      return if rounds.nil? || rounds.empty?

      @rounds = rounds.map.with_index do |(round_str, trump), index|
        round_numbers = round_str.split(",").map(&:to_i)
        starting_player = @players[index % @players.length]
        round = Round.new(self, round_numbers.first, round_numbers.last, trump == "trump", starting_player)
        @current_round = round if index == 0 # set current round to the first round

        [ round_numbers.first, round ]
      end.to_h
      @max_round_number = @rounds.keys.max
    end
end
