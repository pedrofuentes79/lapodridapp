class Round < ApplicationRecord
  belongs_to :game
  has_many :bids, dependent: :destroy

  after_create :create_bids_for_players

  def forbidden_number
    return nil unless bids.where.not(predicted_tricks: nil).count == game.players.count - 1
    cards_dealt - total_asked_bids
  end

  def total_asked_bids
    bids.sum(:predicted_tricks)
  end

  def points_for_player(player)
    bids.find_by(player: player).points
  end

  def player_asks_for_tricks(player, number_of_tricks)
    bid = bids.find_by(player: player)
    if bid.predicted_tricks.present?
      raise "Player #{player.name} has already asked for tricks"
    end
    if number_of_tricks > cards_dealt
      raise "Player #{player.name} can't ask for more tricks than the number of cards dealt"
    end
    if number_of_tricks == forbidden_number
      raise "Player #{player.name} can't ask for #{forbidden_number} tricks"
    end

    bid.update(predicted_tricks: number_of_tricks)
  end

  def player_makes_tricks(player, number_of_tricks)
    bid = bids.find_by(player: player)
    
    if bid.predicted_tricks.nil?
      raise "Player #{player.name} hasn't asked for tricks yet"
    end
    
    # this allows to overwrite the `made_tricks` value if needed
    if number_of_tricks > cards_dealt
      raise "Player #{player.name} can't make more tricks than the number of cards dealt"
    end
    bid.update(actual_tricks: number_of_tricks)
  end

  def complete?
    bids.where(actual_tricks: nil).count == 0
  end

  private

  def create_bids_for_players
    game.players.each do |player|
      bids.create(player: player)
    end
  end
end
