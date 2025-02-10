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

    def broadcast_update
        broadcast_update_leaderboard
    end
end
