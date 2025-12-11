class Bid < ApplicationRecord
  belongs_to :round
  belongs_to :player

  validates :player_id, uniqueness: { scope: :round_id }
  with_options numericality: { greater_than_or_equal_to: 0 }, allow_nil: true do
    # validate that no one makes/asks for more tricks than the number of cards dealt
    validates :predicted_tricks, numericality: { less_than_or_equal_to: ->(bid) { bid.round&.cards_dealt } }
    validates :actual_tricks, numericality: { less_than_or_equal_to: ->(bid) { bid.round&.cards_dealt } }
  end
  # todo: have a point calculation strategy? so it's not fixed
  def points
    return nil unless actual_tricks.present?
    if predicted_tricks == actual_tricks
      10 + actual_tricks * 2
    else
      actual_tricks 
    end
  end
end
