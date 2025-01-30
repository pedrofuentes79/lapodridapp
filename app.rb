require 'sinatra/base'
require 'json'
require 'securerandom'

require_relative './app/models/game'

class MyApp < Sinatra::Base
  set :public_folder, 'public'
  set :views, File.join(File.dirname(__FILE__), 'app/views')
  set :erb, :layout => :'layouts/application.html'

  # Enable JSON body parsing
  before do
    if request.content_type == 'application/json'
      request.body.rewind
      @request_payload = JSON.parse(request.body.read)
    end
  end

  get '/' do
    send_file File.join(settings.public_folder, 'index.html')
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

  post '/api/ask_for_tricks' do
    content_type :json
    player = @request_payload['player']
    tricks = @request_payload['tricks'].to_i
    game = Game.find(@request_payload['game_id'])

    begin
      game.ask_for_tricks(player, tricks)
      status 200
    rescue => e
      status 400
      { error: e.message }.to_json
    end
  end

  post '/api/register_tricks' do
    content_type :json
    player = @request_payload['player']
    tricks = @request_payload['tricks'].to_i
    game = Game.find(@request_payload['game_id'])

    begin
      game.register_tricks(player, tricks)
      status 200
    rescue => e
      status 400
      { error: e.message }.to_json
    end
  end

  get '/api/leaderboard' do
    content_type :json
    game = Game.find(params[:game_id])
    puts "Leaderboard: #{game.leaderboard.to_json}"
    game.leaderboard.to_json
  end

  # Start the server if this file is executed directly.
  run! if app_file == $0
end
