# TODO: starts_at is redundant. It can be computed like this
# starts_at = round_number % game.players.count
# i'm leaving it rn just because it doesn't bother me that much...

class Round < ApplicationRecord
  belongs_to :game
  has_many :bids, dependent: :destroy

  validate :round_number_is_sequential
  validate :validate_cards_dealt_respects_french_deck
  validates :round_number, numericality: { greater_than_or_equal_to: 1 }

  after_create :create_bids_for_players

  def forbidden_number
    return nil unless bids.where.not(predicted_tricks: nil).count == game.players.count - 1
    cards_dealt - total_asked_tricks
  end

  def total_asked_tricks
    bids.sum(:predicted_tricks)
  end

  def total_made_tricks
    bids.sum(:actual_tricks)
  end

  def points_for_player(player)
    bids.find_by(player: player).points
  end

  # this method allows the player to rewrite its previous bid
  def player_asks_for_tricks(player, number_of_tricks)
    bid = bid_for(player)
    validate_tricks_within_cards_dealt!(player, number_of_tricks)
    validate_forbidden_number!(player, number_of_tricks)

    # if the player has already asked for tricks, we need to validate that the new bid makes the total number of tricks consistent
    validate_overwrite_maintains_total_asked_tricks!(player, bid, number_of_tricks) if all_players_have_asked_for_tricks?

    bid.update(predicted_tricks: number_of_tricks)
  end


  # this method allows the player to rewrite its previous `actual_tricks`
  def player_makes_tricks(player, number_of_tricks)
    bid = bid_for(player)
    validate_player_has_asked_for_tricks!(player, bid)
    validate_tricks_within_cards_dealt!(player, number_of_tricks)
    bid.update(actual_tricks: number_of_tricks)
  end

  def is_last_player_to_make_tricks(player)
    # only one bid remaining to be made, and it's for this player
    bids_remaining = bids.where(actual_tricks: nil)
    bids_remaining.count == 1 and bids_remaining.first.player == player
  end

  def all_players_have_asked_for_tricks?
    bids.where(predicted_tricks: nil).count == 0
  end

  def bid_for(player)
    bids.find_by(player: player)
  end

  def all_players_made_tricks?
    bids.where(actual_tricks: nil).count == 0
  end

  def valid_state?
    all_players_made_tricks? and total_made_tricks == cards_dealt and total_asked_tricks != cards_dealt
  end

  def maximum_cards_dealt
    # 51 is the number of cards in the deck after having one for the `trump`.
    # If the round doesn't have trump, there is one more card available
    total_available_cards = has_trump? ? 51 : 52
    (total_available_cards / game.players.count).floor
  end

  def starting_player
    game.players.find_by(game_participations: { position: starts_at })
  end

  private

  def round_number_is_sequential
    return unless game.present? && round_number.present?

    errors_array = game.validate_round_number_sequential(round_number, exclude_round_id: id)
    errors_array.each do |error_message|
      errors.add(:round_number, error_message)
    end
  end

  def validate_player_has_asked_for_tricks!(player, bid)
    raise "Player #{player.name} hasn't asked for tricks yet" if bid.predicted_tricks.nil?
  end

  def validate_forbidden_number!(player, number_of_tricks)
    raise "Player #{player.name} can't ask for #{forbidden_number} tricks" if number_of_tricks == forbidden_number
  end

  def validate_tricks_within_cards_dealt!(player, number_of_tricks)
    raise "Invalid number of tricks" if number_of_tricks > cards_dealt
  end

  def validate_last_player_tricks!(player, number_of_tricks)
    remaining_tricks = cards_dealt - total_made_tricks
    if number_of_tricks != remaining_tricks
      raise "Player #{player.name} can only make #{remaining_tricks} tricks"
    end
  end

  def validate_overwrite_maintains_total!(player, bid, number_of_tricks)
    old_tricks = bid.actual_tricks
    new_total = total_made_tricks - old_tricks + number_of_tricks

    if new_total != cards_dealt
      raise "Player #{player.name} can only make #{cards_dealt - total_made_tricks + old_tricks} tricks"
    end
  end

  def validate_overwrite_maintains_total_asked_tricks!(player, bid, number_of_tricks)
    old_tricks = bid.predicted_tricks
    new_total = total_asked_tricks - old_tricks + number_of_tricks

    # this is because the total number of asked tricks can never be equal to the number of cards dealt
    raise "Player #{player.name} can't ask for #{number_of_tricks} tricks" if new_total == cards_dealt
  end

  def create_bids_for_players
    game.players.each do |player|
      bids.create(player: player)
    end
  end

  def validate_cards_dealt_respects_french_deck
    raise "Game must have players before creating rounds" if game.players.count == 0
    raise "Invalid number of cards dealt" if cards_dealt > maximum_cards_dealt
  end
end
