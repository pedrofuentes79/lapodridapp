module LaPodrida
  module Tracking
    class Round
      PHASES = %i[bidding playing complete].freeze

      attr_reader :players, :cards_dealt, :starting_position, :bids, :tricks_won, :phase

      def initialize(players:, cards_dealt:, starting_position: 1, phase: :bidding, bids: {}, tricks_won: {})
        raise ArgumentError, "players cannot be empty" if players.empty?
        raise ArgumentError, "cards_dealt must be positive" if cards_dealt < 1

        @players = players.freeze
        @cards_dealt = cards_dealt
        @starting_position = starting_position
        @phase = phase
        @bids = bids
        @tricks_won = tricks_won
      end

      def players_in_order
        rotation = (starting_position - 1) % players.size
        players.rotate(rotation)
      end

      def current_bidder
        return nil unless phase == :bidding

        players_in_order.find { |p| !bids.key?(p) }
      end

      def last_bidder?(player)
        bids.size == players.size - 1 && !bids.key?(player)
      end

      def forbidden_number
        Core::ForbiddenBid.forbidden_number(
          cards_dealt:,
          bids:,
          player_count: players.size
        )
      end

      def place_bid(player, count)
        validate_phase!(:bidding)
        validate_player!(player)
        validate_bid_count!(count)
        validate_not_forbidden!(player, count)

        @bids[player] = count
        advance_to_playing if all_bids_placed?

        self
      end

      def can_change_bid?(player)
        phase == :bidding && bids.key?(player)
      end

      def change_bid(player, new_count)
        validate_phase!(:bidding)
        raise InvalidBid, "#{player} has not bid yet" unless bids.key?(player)
        validate_bid_count!(new_count)

        old_bid = @bids.delete(player)
        if forbidden?(new_count)
          @bids[player] = old_bid
          raise ForbiddenBidError, "Cannot bid #{new_count} - it's the forbidden number"
        end

        @bids[player] = new_count
        self
      end

      def record_tricks(player, count)
        validate_phase!(:playing)
        validate_player!(player)
        validate_trick_count!(count)

        @tricks_won[player] = count
        advance_to_complete if all_tricks_recorded?

        self
      end

      def change_tricks(player, new_count)
        validate_phase!(:playing)
        validate_player!(player)
        validate_trick_count!(new_count)

        @tricks_won[player] = new_count
        self
      end

      def points_for(player)
        return nil unless tricks_won.key?(player) && bids.key?(player)

        Core::Scoring.points(
          predicted: bids[player],
          actual: tricks_won[player]
        )
      end

      def total_bids
        bids.values.sum
      end

      def total_tricks
        tricks_won.values.sum
      end

      def valid?
        phase == :complete &&
          total_tricks == cards_dealt &&
          total_bids != cards_dealt
      end

      def invalid?
        phase == :complete && !valid?
      end

      def bidding? = phase == :bidding
      def playing? = phase == :playing
      def complete? = phase == :complete

      def to_h
        {
          players: players,
          cards_dealt: cards_dealt,
          starting_position: starting_position,
          phase: phase,
          bids: bids.dup,
          tricks_won: tricks_won.dup
        }
      end

      def self.from_h(hash)
        new(
          players: hash[:players] || hash["players"],
          cards_dealt: hash[:cards_dealt] || hash["cards_dealt"],
          starting_position: hash[:starting_position] || hash["starting_position"] || 1,
          phase: (hash[:phase] || hash["phase"])&.to_sym || :bidding,
          bids: hash[:bids] || hash["bids"] || {},
          tricks_won: hash[:tricks_won] || hash["tricks_won"] || {}
        )
      end

      private

      def validate_phase!(expected)
        return if phase == expected

        raise InvalidPhase, "Expected #{expected} phase, currently in #{phase}"
      end

      def validate_player!(player)
        return if players.include?(player)

        raise ArgumentError, "Unknown player: #{player}"
      end

      def validate_bid_count!(count)
        raise InvalidBid, "Bid must be non-negative" if count.negative?
        raise InvalidBid, "Bid cannot exceed cards dealt (#{cards_dealt})" if count > cards_dealt
      end

      def validate_trick_count!(count)
        raise InvalidTrickCount, "Tricks must be non-negative" if count.negative?
        raise InvalidTrickCount, "Tricks cannot exceed cards dealt (#{cards_dealt})" if count > cards_dealt
      end

      def validate_not_forbidden!(player, count)
        return unless last_bidder?(player) && forbidden?(count)

        raise ForbiddenBidError, "Cannot bid #{count} - it's the forbidden number"
      end

      def forbidden?(count)
        Core::ForbiddenBid.forbidden?(
          cards_dealt:,
          bids:,
          player_count: players.size,
          new_bid: count
        )
      end

      def all_bids_placed?
        bids.size == players.size
      end

      def all_tricks_recorded?
        tricks_won.size == players.size
      end

      def advance_to_playing
        @phase = :playing
      end

      def advance_to_complete
        @phase = :complete
      end
    end
  end
end
