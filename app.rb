require 'sinatra'
require 'json'
require './app/models/game'
require 'securerandom'

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
  puts "Creating game with players #{players} and rounds #{rounds}"

  game = Game.new(players, rounds)
  game.start

  redirect "/game/#{game.id}"
end

get '/game/:id' do
  @game = Game.find(params[:id])
  erb :game
end

post '/api/ask_for_tricks' do
  content_type :json
  player = @request_payload['player']
  tricks = @request_payload['tricks'].to_i

  begin
    @game.current_round.ask_for_tricks(player, tricks)
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

  begin
    @game.current_round.register_tricks(player, tricks)
    status 200
  rescue => e
    status 400
    { error: e.message }.to_json
  end
end