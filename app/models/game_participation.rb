class GameParticipation < ApplicationRecord
  belongs_to :player
  belongs_to :game

  # can't be twice in the same game
  validates :player_id, uniqueness: { scope: :game_id }
  validates :position, presence: true, uniqueness: { scope: :game_id }, numericality: { greater_than_or_equal_to: 1 }

  # default_scope { order(:position) }
end
