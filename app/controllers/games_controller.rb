class GamesController < ApplicationController
  protect_from_forgery with: :null_session

  def index
    render :index
  end

  def new
    @game = Game.new
  end

  def create
    players = game_params[:players]
    rounds = game_params[:rounds]

    rounds = rounds.to_h if rounds.is_a?(ActionController::Parameters)
    players = players.to_a if players.is_a?(ActionController::Parameters)

    @game = Game.new(players, rounds)

    if @game.valid?
      @game.start
      respond_to do |format|
        format.html { redirect_to game_path(@game.id) }
        format.json { render json: @game, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  def game_params
    params.require(:game).permit(players: [], rounds: {})
  end
  def show
    @game = Game.find(params[:id])
    respond_to do |format|
      format.html { render :spreadsheet }
      format.json { render json: @game }
    end
  end
  # TODO:
  # this one should actually display a winners page, with only the leaderboard and some other stats...
  def winners
    @game = Game.find(params[:id])
    if @game
      render json: @game.leaderboard
    else
      render json: { error: "Game not found" }, status: :not_found
    end
  end

  private

  def game_params
    params.require(:game).permit(players: [], rounds: {})
  end
end
