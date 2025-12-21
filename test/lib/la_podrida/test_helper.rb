require "minitest/autorun"
require "active_support/testing/declarative"
require_relative "../../../lib/la_podrida"

module LaPodrida
  class TestCase < Minitest::Test
    extend ActiveSupport::Testing::Declarative

    def player_names(count = 4)
      ("A".."Z").first(count)
    end

    def setup_round(cards_dealt:, player_count: 4, starting_position: 1)
      Tracking::Round.new(
        players: player_names(player_count),
        cards_dealt:,
        starting_position:
      )
    end

    def setup_game(player_count: 4)
      Tracking::Game.new(players: player_names(player_count))
    end
  end
end
