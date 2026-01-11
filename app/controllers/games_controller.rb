class GamesController < ApplicationController
  def index
    @games = Game.order(created_at: :desc)
  end

  def new
  end

  def create
    players = params[:players].split(",").map(&:strip).reject(&:blank?)
    cards = params[:cards].split(",").map { |c| c.strip.to_i }.reject(&:zero?)

    @game = Game.create_game(players:, cards_per_round: cards)
    redirect_to @game
  rescue LaPodrida::Error, ArgumentError => e
    redirect_to new_game_path, alert: e.message
  end

  def show
    @game = Game.find(params[:id])
  end

  def destroy
    Game.find(params[:id]).destroy
    redirect_to games_path
  end

  def bid
    @game = Game.find(params[:id])
    round = @game.engine.rounds[params[:round].to_i]
    player = params[:player]

    if params[:asked].present?
      if round.bids[player]
        round.correct_bid(player, params[:asked].to_i)
      else
        round.place_bid(player, params[:asked].to_i)
      end
    end

    if params[:made].present?
      if round.tricks_won[player]
        round.correct_tricks(player, params[:made].to_i)
      else
        round.record_tricks(player, params[:made].to_i)
      end
    end

    @game.save_engine!
    redirect_to @game
  rescue LaPodrida::Error => e
    redirect_to @game, alert: e.message
  end
end
