class Game < ApplicationRecord
  has_many :game_participations
  has_many :players, through: :game_participations
  has_many :rounds, dependent: :destroy

  validates :current_round_number, numericality: { greater_than_or_equal_to: 0 }

  # NOTE: in these two methods, we don't validate that the current round is the one we're asking for
  # because we want users to be able to rewrite the previous state if needed in case of an error.
  def ask_for_tricks(round, player, number_of_tricks)
    # is the previous round complete?
    raise "Previous round hasn't been completed yet" unless is_previous_round_complete?(round)

    round.player_asks_for_tricks(player, number_of_tricks)
  end

  def make_tricks(round, player, number_of_tricks)
    # is the previous round complete?
    raise "Previous round hasn't been completed yet" unless is_previous_round_complete?(round)

    round.player_makes_tricks(player, number_of_tricks)
  end


  def is_previous_round_complete?(round)
    prev = previous_round(round.round_number)
    return prev.nil? || prev.complete?
  end

  def previous_round(round_number)
    return nil unless round_number >= 1
    rounds.find_by(round_number: round_number - 1)
  end

  def current_round
    rounds.find_by(round_number: current_round_number)
  end
end
