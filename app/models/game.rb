# TODO: add a method to create a round and automatically set the round_number
class Game < ApplicationRecord
  has_many :game_participations, dependent: :destroy
  has_many :players, through: :game_participations
  has_many :rounds, dependent: :destroy, before_add: :validate_sequential_round_number

  validates :current_round_number, numericality: { greater_than_or_equal_to: 0 }


  # -------------------------------- GAME BUSINESS LOGIC --------------------------------

  # NOTE: in these two methods, we don't validate that the current round is the one we're asking for
  # because we want users to be able to rewrite the previous state if needed in case of an error.
  def ask_for_tricks(round, player, number_of_tricks)
    # is the previous round complete?
    # raise "Previous round hasn't been completed yet" unless all_players_made_tricks_in_previous_rounds?(round)
    validate_all_previous_rounds_are_valid?(round)

    round.player_asks_for_tricks(player, number_of_tricks)
  end

  def make_tricks(round, player, number_of_tricks)
    # is the previous round complete?
    # raise "Previous round hasn't been completed yet" unless all_players_made_tricks_in_previous_rounds?(round)
    validate_all_previous_rounds_are_valid?(round)

    round.player_makes_tricks(player, number_of_tricks)
  end

  def create_next_round(cards_dealt, has_trump: true)
    assert_sequential_incremental_round_numbers

    biggest_round_number = rounds.maximum(:round_number)
    new_round_number = biggest_round_number.present? ? biggest_round_number + 1 : 0

    rounds.create(cards_dealt: cards_dealt, round_number: new_round_number, has_trump: has_trump)
  end

  # -------------------------------- HELPERS --------------------------------

  def previous_round(round_number)
    return nil unless round_number >= 1
    rounds.find_by(round_number: round_number - 1)
  end

  def current_round
    rounds.find_by(round_number: current_round_number)
  end

  def all_players_made_tricks_in_previous_rounds?(round)
    prev = previous_round(round.round_number)
    prev.nil? || prev.all_players_made_tricks?
  end

  # -------------------------------- VALIDATIONS --------------------------------

  def validate_round_number_sequential(round_number, exclude_round_id: nil)
    rounds_to_check = rounds.where.not(id: exclude_round_id)
    max_round_number = rounds_to_check.maximum(:round_number)

    return [] if max_round_number.nil? # this means there are no rounds yet
    return [ "must be sequential. Expected #{max_round_number + 1}, got #{round_number}" ] unless round_number == max_round_number + 1
    validate_existing_rounds_are_sequential(rounds_to_check)
  end

  def validate_sequential_round_number(round)
    errors = validate_round_number_sequential(round.round_number, exclude_round_id: round.id)
    raise "The round numbers are not sequential" unless errors.empty?
  end

  def assert_sequential_incremental_round_numbers
    errors = validate_existing_rounds_are_sequential(rounds)
    raise "The round numbers are not sequential" unless errors.empty?
  end

  private

  def validate_all_previous_rounds_are_valid?(round)
    previous_rounds = rounds.where(round_number: (0..round.round_number - 1))
    previous_rounds.each do |round|
      raise "The previous round is invalid. You need to correct it to move on to the next round" unless round.valid_state?
    end
  end

  def validate_existing_rounds_are_sequential(rounds_to_check)
    nums = rounds_to_check.pluck(:round_number).sort
    return [] if nums.empty?
    if nums != (nums.first..nums.last).to_a
      return [ "is not sequential - there are gaps in existing rounds" ]
    end
    []
  end
end
