class GamesController < ApplicationController
  def index
    # List all games (we might want to add some filtering later)
    # @games = Game.all
  end

  def show
    @game = Game.find(params[:id])
    render :show
  end

  def new
    # creates an empty game, so that we can add players and rounds to it later?
    # this will generate errors though...
    @game = Game.new
  end

  def create
    @game = Game.new(game_params)
    
    if @game.valid?
      redirect_to game_path(@game)
    else
      render :new
    end
  end

  def start
    @game = Game.find(params[:id])
    @game.start
    redirect_to game_path(@game)
  end

  # def ask_tricks
  #   @game = Game.find(params[:id])
  #   @game.ask_for_tricks(params[:player], params[:tricks].to_i)
  #   redirect_to game_path(@game)
  # rescue ArgumentError => e
  #   flash[:error] = e.message
  #   redirect_to game_path(@game)
  # end

  # def register_tricks
  #   @game = Game.find(params[:id])
  #   @game.register_tricks(params[:player], params[:tricks].to_i)
  #   redirect_to game_path(@game)
  # rescue ArgumentError => e
  #   flash[:error] = e.message
  #   redirect_to game_path(@game)
  # end

  def leaderboard
    @game = Game.find(params[:id])
    @leaderboard = @game.leaderboard
    render :leaderboard
  end

  private

  def game_params
    params.require(:game).permit(players: [], rounds: {})
  end
end
