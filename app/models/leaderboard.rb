# TODO: integrate with Game object
class Leaderboard
    def initialize(game)
        @game = game
    end

    def update
        total_points = Hash.new(0)
        @game.rounds.each_value do |round|
            round.points.each do |player, points|
                total_points[player] += points
            end
        end
        @leaderboard = total_points.sort_by { |player, points| -points }.to_h

        update_turbo_observer
    end

    def update_turbo_observer
        Turbo::StreamsChannel.broadcast_replace_to(
            "game_#{@game.id}",
            target: "leaderboard-body",
            partial: "games/leaderboard",
            locals: { game: @game }
        )
    end
end
