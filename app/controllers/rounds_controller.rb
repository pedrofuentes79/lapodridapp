class RoundsController < ApplicationController
  before_action :set_game
  before_action :set_round, only: [ :show, :ask_for_tricks, :make_tricks, :update_bid, :points ]

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

  def points
    player = Player.find(params[:player_id])
    bid = @round.bids.find_by(player_id: player.id)
    points_frame_id = "points_#{@round.id}_#{player.id}"

    if turbo_frame_request?
      return render partial: "games/points_cell", locals: { round: @round, player: player, bid: bid, frame_id: points_frame_id }
    end

    redirect_to @game
  end

  # Updates a single player's bid for a round (asked + made) from the game status grid.
  # Intended to be used with Turbo Frames.
  def update_bid
    player = Player.find(params[:player_id])

    asked = params[:predicted_tricks]
    made = params[:actual_tricks]

    begin
      if asked.present?
        @game.ask_for_tricks(@round, player, asked.to_i)
      end

      if made.present?
        @game.make_tricks(@round, player, made.to_i)
      end

      bid = @round.reload.bids.find_by(player_id: player.id)
      frame_id = "bid_cell_#{@round.id}_#{player.id}"

      if turbo_frame_request?
        # Update the status cell
        status_cell_html = render_to_string partial: "games/status_cell", locals: { game: @game, round: @round, player: player, bid: bid, frame_id: frame_id }

        # Update all points frames for all players in this round
        @players = @game.game_participations.includes(:player).order(:position).map(&:player)
        points_updates = @players.map do |p|
          p_bid = @round.bids.find_by(player_id: p.id)
          points_frame_id = "points_#{@round.id}_#{p.id}"
          points_html = render_to_string partial: "games/points_cell", locals: { round: @round, player: p, bid: p_bid, frame_id: points_frame_id }
          turbo_stream.update(points_frame_id, points_html)
        end

        # Return turbo_stream response with status cell update and all points updates
        # Turbo will handle updating the frame specified in the request AND the additional points frames
        render turbo_stream: [
          turbo_stream.update(frame_id, status_cell_html),
          *points_updates
        ]
        return
      end

      redirect_to @game
    rescue RuntimeError => e
      bid = @round.reload.bids.find_by(player_id: player.id)
      frame_id = "bid_cell_#{@round.id}_#{player.id}"

      if turbo_frame_request?
        return render partial: "games/status_cell", status: :unprocessable_entity,
               locals: { game: @game, round: @round, player: player, bid: bid, frame_id: frame_id, error_message: e.message }
      end

      redirect_to @game, alert: e.message
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
