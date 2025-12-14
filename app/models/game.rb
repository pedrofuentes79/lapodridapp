# TODO: add a method to create a round and automatically set the round_number
# TODO: maybe create a GameRoundManager to handle creating the next round, the current round number
# and the passing to the next round... idk maybe it's okay to have it here...

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
    validate_all_previous_rounds_are_valid?(round)

    round.player_asks_for_tricks(player, number_of_tricks)
  end

  def make_tricks(round, player, number_of_tricks)
    # is the previous round complete?
    validate_all_previous_rounds_are_valid?(round)

    round.player_makes_tricks(player, number_of_tricks)

    update_current_round_number!
  end

  def create_next_round(cards_dealt, has_trump: true)
    assert_sequential_incremental_round_numbers

    biggest_round_number = rounds.maximum(:round_number)
    new_round_number = biggest_round_number.present? ? biggest_round_number + 1 : 0

    starting_position = new_round_number % players.count
    rounds.create(cards_dealt: cards_dealt, round_number: new_round_number, has_trump: has_trump, starts_at: starting_position)
  end

  def winner
    return nil unless all_rounds_over?

    rounds.includes(bids: :player)                        # eager load bids and players
          .flat_map(&:bids)                               # flatten the bids into a single array
          .group_by(&:player)
          .transform_values { |bids| bids.sum(&:points) }
          .max_by { |player, points| points }             # find the player with the highest points
          &.first                                         # return that player
  end

  def position_of(player)
    game_participations.find_by(player: player)&.position
  end

  # -------------------------------- HELPERS --------------------------------

  def previous_round(round_number)
    return nil unless round_number >= 1
    rounds.find_by(round_number: round_number - 1)
  end

  def all_rounds_over?
    rounds.all? { |round| round.valid_state? }
  end

  def current_round
    rounds.find_by(round_number: current_round_number)
  end

  def maximum_cards_dealt_for_players(player_count, has_trump: true)
    # 51 is the number of cards in the deck after having one for the `trump`.
    # If the round doesn't have trump, there is one more card available
    total_available_cards = has_trump ? 51 : 52
    return 0 if player_count.zero?
    (total_available_cards / player_count).floor
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

  def update_current_round_number!
    # get the biggest round number of the rounds that are over
    # if there are no rounds that are over, current round number would be 0 (0-indexed for now)
    biggest_over_round_number = rounds.select(&:valid_state?).map(&:round_number).max
    # this is to prevent the current round number from being greater than the total number of rounds
    final_round_number = biggest_over_round_number ? [ rounds.maximum(:round_number), biggest_over_round_number + 1 ].min : 0
    update(current_round_number: final_round_number)
  end
end
