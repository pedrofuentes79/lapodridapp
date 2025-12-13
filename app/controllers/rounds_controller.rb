class RoundsController < ApplicationController
  before_action :set_game
  before_action :set_round, only: [ :show, :ask_for_tricks, :make_tricks ]

  def index
    @rounds = @game.rounds.order(:round_number)
  end

  def show
  end

  def create
    cards_dealt = params[:cards_dealt].to_i
    has_trump = params[:has_trump] == "true"

    begin
      @round = @game.create_next_round(cards_dealt, has_trump: has_trump)
      redirect_to [ @game, @round ], notice: "Round created successfully."
    rescue RuntimeError => e
      redirect_to @game, alert: e.message
    end
  end

  def ask_for_tricks
    player = Player.find(params[:player_id])
    number_of_tricks = params[:number_of_tricks].to_i

    begin
      @game.ask_for_tricks(@round, player, number_of_tricks)
      redirect_to [ @game, @round ], notice: "#{player.name} asked for #{number_of_tricks} tricks."
    rescue RuntimeError => e
      redirect_to [ @game, @round ], alert: e.message
    end
  end

  def make_tricks
    player = Player.find(params[:player_id])
    number_of_tricks = params[:number_of_tricks].to_i

    begin
      @game.make_tricks(@round, player, number_of_tricks)
      redirect_to [ @game, @round ], notice: "#{player.name} made #{number_of_tricks} tricks."
    rescue RuntimeError => e
      redirect_to [ @game, @round ], alert: e.message
    end
  end

  private

  def set_game
    @game = Game.find(params[:game_id])
  end

  def set_round
    @round = @game.rounds.find(params[:id])
  end
end
