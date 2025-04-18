require 'sinatra/base'
require 'json'
require 'securerandom'

# require_relative 'app/models/point_calculation_strategy'
# require_relative 'app/models/round'
# require_relative 'app/models/game'
require_relative 'app/controllers/games_controller'

class MyApp < Sinatra::Base
  set :public_folder, 'public'
  set :views, File.join(File.dirname(__FILE__), 'app/views')
  set :erb, layout: :'layouts/application.html'

  # Mount the GamesController to handle game-related routes
  use GamesController

  # Enable JSON body parsing
  before do
    if request.content_type == 'application/json'
      request.body.rewind
      @request_payload = JSON.parse(request.body.read)
    end
  end

  post '/api/game' do
    content_type :json
    players = @request_payload['players']
    rounds = @request_payload['rounds']

    game = Game.new(players, rounds)
    game.start

    redirect "/game/#{game.id}"
  end

  get '/game/:id' do
    @game = Game.find(params[:id])
    erb :spreadsheet
  end

  post '/api/update_game_state' do
    content_type :json
    game = Game.find(@request_payload['game_id'])
    game.update_state(@request_payload['game_state'])
    status 200
    game.to_json
  end

  get '/api/leaderboard' do
    content_type :json
    game_id = params[:game_id]
    game = Game.find(game_id)
    game.leaderboard.to_json
  end

  # Start the server if this file is executed directly.
  run! if app_file == $0
end
