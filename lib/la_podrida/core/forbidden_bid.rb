module LaPodrida
  module Core
    # In La Podrida, the last player to bid cannot bid a number that would
    # make the total bids equal the cards dealt. This ensures someone must
    # fail their bid.
    module ForbiddenBid
      module_function

      def forbidden_number(cards_dealt:, bids:, player_count:)
        return nil unless bids.size == player_count - 1

        forbidden = cards_dealt - bids.values.sum
        return nil if forbidden.negative?

        forbidden
      end

      def forbidden?(cards_dealt:, bids:, player_count:, new_bid:)
        forbidden = forbidden_number(cards_dealt:, bids:, player_count:)
        return false if forbidden.nil?

        new_bid == forbidden
      end
    end
  end
end
