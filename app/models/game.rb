class Game < ApplicationRecord
  validates :state, presence: true

  def engine
    data = state.is_a?(String) ? JSON.parse(state) : state
    @engine ||= LaPodrida::Tracking::Game.from_h(data.deep_symbolize_keys)
  end

  delegate :players, :rounds, :scores, :winner, :complete?, :current_round, :current_round_number, to: :engine

  def save_engine!
    update!(state: engine.to_h)
    @engine = nil
  end

  def self.create_game(players:, cards_per_round:)
    engine = LaPodrida::Tracking::Game.new(players:)
    cards_per_round.each { |cards| engine.create_round(cards_dealt: cards) }
    create!(state: engine.to_h)
  end
end
