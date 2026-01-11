class Player < ApplicationRecord
  validates :name, presence: true
  has_many :game_participations
  has_many :games, through: :game_participations
end
