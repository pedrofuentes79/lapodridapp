module Api
  class GamesController < ApplicationController
    protect_from_forgery with: :null_session

    def update_state
      @game = Game.find(params[:id])
      if @game.update_state(params[:game_state])
        render json: @game
      else
        render json: @game.errors
      end
    end

    def leaderboard
      @game = Game.find(params[:id])
      if @game
        render json: @game.leaderboard
      else
        render json: { error: "Game not found" }, status: :not_found
      end
    end
  end
end