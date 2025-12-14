class GameParticipation < ApplicationRecord
  belongs_to :player
  belongs_to :game

  # can't be twice in the same game
  validates :player_id, uniqueness: { scope: :game_id }
  # can't have two players in the same position (in the same game)
  validates :position, presence: true, uniqueness: { scope: :game_id }, numericality: { greater_than_or_equal_to: 1 }

end
