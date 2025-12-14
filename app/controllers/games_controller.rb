class GamesController < ApplicationController
  before_action :set_game, only: [ :show, :update, :destroy, :add_player ]

  def index
    @games = Game.all
  end

  def new
    @game = Game.new
    @players_params = default_players_params(params[:players])
    @rounds_params = default_rounds_params(params[:rounds])
    @player_count = count_players(@players_params)
  end

  def show
    @players = @game.game_participations.includes(:player).order(:position).map(&:player)
    @rounds = @game.rounds.includes(bids: :player).order(:round_number)
  end

  def preview
    @game = Game.new
    @players_params = default_players_params(params[:players])
    @rounds_params = default_rounds_params(params[:rounds])
    @player_count = count_players(@players_params)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "rounds_fields",
          partial: "games/rounds_fields",
          locals: { rounds_params: @rounds_params, player_count: @player_count }
        )
      end

      format.html do
        render partial: "games/rounds_fields", locals: { rounds_params: @rounds_params, player_count: @player_count }
      end
    end
  end

  def create
    @game = Game.new(current_round_number: 0)
    @players_params = default_players_params(params[:players])
    @rounds_params = default_rounds_params(params[:rounds])
    @player_count = count_players(@players_params)

    # Validate and process players first
    players_data = []
    players_source = normalize_indexed_params(params[:players])
    if players_source.present?
      players_source.each_with_index do |player_params, index|
        player_name = player_params[:name].to_s.strip
        next if player_name.blank?
        players_data << { name: player_name, index: index }
      end
    end

    if players_data.empty?
      @game.errors.add(:base, "At least one player is required")
      return render :new, status: :unprocessable_entity
    end

    # Validate rounds before saving
    rounds_data = []
    rounds_source = normalize_indexed_params(params[:rounds])
    if rounds_source.present?
      rounds_source.each_with_index do |round_params, index|
        cards_dealt = round_params[:cards_dealt].to_i
        next if cards_dealt.zero?
        has_trump = round_params[:has_trump] == "1" || round_params[:has_trump] == true
        rounds_data << { cards_dealt: cards_dealt, has_trump: has_trump, index: index }
      end
    end

    if rounds_data.empty?
      @game.errors.add(:base, "At least one round is required")
      return render :new, status: :unprocessable_entity
    end

    # Save game first
    unless @game.save
      return render :new, status: :unprocessable_entity
    end

    # Create players and game participations
    players_data.each_with_index do |player_data, position|
      player = Player.find_or_create_by(name: player_data[:name])

      # If player was just created but validation failed
      unless player.persisted?
        @game.errors.add(:base, "Player #{player_data[:index] + 1}: #{player.errors.full_messages.join(', ')}")
        next
      end

      participation = @game.game_participations.build(player: player, position: position)
      unless participation.save
        @game.errors.add(:base, "Player #{player_data[:index] + 1}: #{participation.errors.full_messages.join(', ')}")
      end
    end

    if @game.errors.any?
      @game.destroy
      return render :new, status: :unprocessable_entity
    end

    # Validate rounds before creating them
    player_count = @game.players.count

    rounds_data.each do |round_data|
      has_trump = round_data[:has_trump] == "1" || round_data[:has_trump] == true
      max_cards = @game.maximum_cards_dealt_for_players(player_count, has_trump: has_trump)

      if round_data[:cards_dealt] > max_cards
        @game.errors.add(:base, "Round #{round_data[:index] + 1}: Cards dealt (#{round_data[:cards_dealt]}) exceeds maximum (#{max_cards}) for #{player_count} players#{has_trump ? ' (with trump)' : ' (without trump)'}")
      end
    end

    if @game.errors.any?
      @game.destroy
      return render :new, status: :unprocessable_entity
    end

    # Create rounds after players are added
    rounds_data.each do |round_data|
      has_trump = round_data[:has_trump] == "1" || round_data[:has_trump] == true
      begin
        @game.create_next_round(round_data[:cards_dealt], has_trump: has_trump)
      rescue RuntimeError => e
        @game.errors.add(:base, "Round #{round_data[:index] + 1}: #{e.message}")
      end
    end

    if @game.errors.any?
      # If round creation failed, destroy the game
      @game.destroy
      render :new, status: :unprocessable_entity
    else
      redirect_to @game, notice: "Game was successfully created."
    end
  end

  def update
    if @game.update(game_params)
      render :show
    else
      render json: { errors: @game.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @game.destroy
    head :no_content
  end

  def add_player
    player = Player.find(params[:player_id])
    position = params[:position] || @game.game_participations.count

    participation = @game.game_participations.build(player: player, position: position)

    if participation.save
      render :show
    else
      render json: { errors: participation.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_game
    @game = Game.find(params[:id])
  end

  def game_params
    params.require(:game).permit(:current_round_number, rounds_attributes: [ :cards_dealt ])
  end

  def count_players(players_params)
    players_params.count { |p| p[:name].to_s.strip.present? }
  end

  def default_players_params(raw_players)
    players = normalize_indexed_params(raw_players).map { |p| { name: p[:name].to_s } }
    if players.empty?
      [ { name: "" } ]
    else
      players
    end
  end

  def default_rounds_params(raw_rounds)
    rounds = normalize_indexed_params(raw_rounds).map do |r|
      {
        cards_dealt: r[:cards_dealt].to_s,
        has_trump: (r[:has_trump].to_s == "1" || r[:has_trump] == true)
      }
    end

    if rounds.empty?
      [ { cards_dealt: "", has_trump: true } ]
    else
      rounds
    end
  end

  def normalize_indexed_params(raw)
    return [] if raw.blank?

    source =
      if raw.respond_to?(:to_unsafe_h)
        raw.to_unsafe_h
      else
        raw
      end

    if source.is_a?(Hash)
      source.sort_by { |k, _| k.to_i }.map { |_, v| v }
    else
      Array(source)
    end
  end
end
