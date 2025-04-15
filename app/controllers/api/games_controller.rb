module Api
  class GamesController < ApplicationController
    protect_from_forgery with: :null_session

    def update_state
      @game = Game.find(params[:id])
      if @game.update_state(params[:game_state])
        render json: @game
      else
        render json: @game.errors, status: :unprocessable_entity
      end
    end

    def leaderboard
      @game = Game.find(params[:id])
      render json: @game.leaderboard
    end
  end
end
