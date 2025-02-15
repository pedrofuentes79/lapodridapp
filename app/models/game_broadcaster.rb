class GameBroadcaster
    def initialize(game)
        @game = game
    end

    def broadcast_update_leaderboard
        Turbo::StreamsChannel.broadcast_replace_to(
            "game_#{@game.id}",
            target: "leaderboard-body",
            partial: "games/leaderboard",
            locals: { game: @game }
        )
    end

    def broadcast_update_forbidden_value(round)
        Turbo::StreamsChannel.broadcast_replace_to(
            "game_#{@game.id}",
            target: "forbidden-value-#{round.round_number}",
            partial: "rounds/forbidden_value",
            locals: { round: round }
        )
    end

    def broadcast_update_game
        broadcast_update_leaderboard
    end

    def broadcast_update_round(round)
        broadcast_update_forbidden_value(round)
    end
end
