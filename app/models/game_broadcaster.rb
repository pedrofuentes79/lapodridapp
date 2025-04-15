class GameBroadcaster
    def initialize(game)
        @game = game
    end

    def broadcast_replace(target, partial, locals)
        Turbo::StreamsChannel.broadcast_replace_to(
            "game_#{@game.id}",
            target: target,
            partial: partial,
            locals: locals
        )
    end

    def broadcast_update_leaderboard
        broadcast_replace("leaderboard-body", "games/leaderboard", { game: @game })
    end

    def broadcast_update_forbidden_value(round)
        broadcast_replace("forbidden-value-#{round.round_number}", "rounds/forbidden_value", { round: round })
    end

    def broadcast_update_tricks_cards_ratio(round)
        broadcast_replace("tricks-cards-ratio-#{round.round_number}", "rounds/tricks_cards_ratio", { round: round })
    end

    def broadcast_update_player_points(round, player)
        broadcast_replace("points-#{round.round_number}-#{player}", "rounds/points_per_player", { round: round, player: player })
    end

    def broadcast_update_round(round, players)
        broadcast_update_forbidden_value(round)
        broadcast_update_tricks_cards_ratio(round)

        players.each do |player|
            broadcast_update_player_points(round, player)
        end
    end

    def broadcast_update_game
        broadcast_update_leaderboard
    end
end
