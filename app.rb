require 'sinatra'
require 'json'
require './app/models/game'
require 'securerandom'

set :public_folder, 'public'
set :views, File.join(File.dirname(__FILE__), 'app/views')
set :erb, :layout => :'layouts/application'

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
  puts "Request payload: #{@request_payload.inspect}"
  players = @request_payload['players']
  puts "Players: #{players.inspect}"

  game = Game.new(players)
  puts game.id
  game.start


  redirect "/game/#{game.id}"
end

get '/game/:id' do
  @game = Game.find(params[:id])
  erb :game
end