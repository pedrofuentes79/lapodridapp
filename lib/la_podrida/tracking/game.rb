module LaPodrida
  module Tracking
    class Game
      FRENCH_DECK_SIZE = 52
      TRUMP_RESERVE = 1

      attr_reader :players, :rounds

      def initialize(players:, rounds: [])
        raise ArgumentError, "Se necesitan al menos 2 jugadores" if players.size < 2

        @players = players.freeze
        @rounds = rounds
      end

      def create_round(cards_dealt:, has_trump: true)
        validate_cards_dealt!(cards_dealt, has_trump:)

        starting_position = next_starting_position
        round = Round.new(
          players:,
          cards_dealt:,
          starting_position:
        )
        @rounds << round
        round
      end

      def max_cards_per_player(has_trump: true)
        available = has_trump ? FRENCH_DECK_SIZE - TRUMP_RESERVE : FRENCH_DECK_SIZE
        available / players.size
      end

      def current_round
        rounds.find { |r| !r.complete? } || rounds.last
      end

      def current_round_number
        current = current_round
        return 1 if current.nil?

        rounds.index(current) + 1
      end

      def points_for(player)
        rounds.sum { |r| r.points_for(player) || 0 }
      end

      def scores
        players.to_h { |p| [ p, points_for(p) ] }
      end

      def winner
        return nil unless complete?

        scores.max_by { |_, pts| pts }&.first
      end

      def complete?
        rounds.any? && rounds.all?(&:complete?)
      end

      def valid?
        complete? && rounds.all?(&:valid?)
      end

      def to_h
        {
          players: players,
          rounds: rounds.map(&:to_h)
        }
      end

      def self.from_h(hash)
        rounds_data = hash[:rounds] || hash["rounds"] || []

        new(
          players: hash[:players] || hash["players"],
          rounds: rounds_data.map { |r| Round.from_h(r) }
        )
      end

      private

      def next_starting_position
        return 1 if rounds.empty?

        last_position = rounds.last.starting_position
        (last_position % players.size) + 1
      end

      def validate_cards_dealt!(cards_dealt, has_trump:)
        max = max_cards_per_player(has_trump:)
        return if cards_dealt.positive? && cards_dealt <= max

        raise ArgumentError, "Las cartas deben estar entre 1 y #{max}"
      end
    end
  end
end
