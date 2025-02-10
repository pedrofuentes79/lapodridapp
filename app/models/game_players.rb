class GamePlayers
  include ActiveModel::Model
  include ActiveModel::Validations
  include Enumerable
  
  attr_reader :players

  validates :players, presence: { message: "can't be blank" }
  validate :all_players_must_be_strings

  def initialize(players)
    @players = players || []
  end

  # region ARRAY METHODS
  def each(&block)
    @players.each(&block)
  end

  def [](index)
    @players[index]
  end

  def length
    @players.length
  end

  def index(player)
    @players.index(player)
  end

  def to_json(options = {})
    @players.to_json(options)
  end

  def to_a
    @players
  end
  # endregion

  def next_player_to(player, offset = 1)
    current_index = @players.index(player)
    @players[(current_index + offset) % @players.length]
  end

  def last_player(starting_player)
    next_player_to(starting_player, -1)
  end

  def is_last_player?(player, starting_player)
    player == last_player(starting_player)
  end

  private

  def all_players_must_be_strings
    return if players.nil? || !players.present?

    unless players.all? { |p| p.is_a?(String) }
      errors.add(:players, "must all be strings")
    end
  end
end
