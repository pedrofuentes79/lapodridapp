# TODO: integrate with Game object
class Leaderboard
    def initialize(game)
        @game = game
        @player_points = {}
    end

    def update
        total_points = Hash.new(0)
        @game.rounds.each_value do |round|
            round.points.each do |player, points|
                total_points[player] += points
            end
        end
        @player_points = total_points.sort_by { |player, points| -points }.to_h
        @game.update_turbo_observer
    end

    def each
        @player_points.each do |player, points|
            yield player, points
        end
    end
end
