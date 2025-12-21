module LaPodrida
  class Error < StandardError; end
  class InvalidPhase < Error; end
  class InvalidBid < Error; end
  class ForbiddenBidError < Error; end
  class InvalidTrickCount < Error; end
end

require_relative "la_podrida/core/scoring"
require_relative "la_podrida/core/forbidden_bid"
require_relative "la_podrida/tracking/round"
require_relative "la_podrida/tracking/game"
