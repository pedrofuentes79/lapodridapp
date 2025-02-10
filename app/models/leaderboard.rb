# TODO: integrate with Game object
class Leaderboard
    def initialize(game)
        @game = game
        @scores = {}
        update
    end

    def update
        @scores = calculate_scores
    end

    def to_json(options = {})
        @scores.to_json(options)
    end

    def as_json(options = {})
        @scores
    end

    def each
        @scores.each do |player, points|
            yield player, points
        end
    end

    private

    def calculate_scores
        scores = Hash.new(0)
        return scores if @game.rounds.nil?

        @game.rounds.each do |_round_number, round|
            next if round.points.nil?

            round.points.each do |player, points|
                scores[player] ||= 0
                scores[player] += points if points
            end
        end

        scores
    end
end
