class Round
    attr_reader :round_number, :amount_of_cards, :amount_of_asked_tricks,
                :asked_tricks, :current_player, :tricks_made, :points, :starting_player

    def initialize(game, round_number, amount_of_cards, is_trump, starting_player)
        @game = game
        @round_number = round_number
        @amount_of_cards = amount_of_cards
        @is_trump = is_trump
        @starting_player = starting_player
        @current_player = starting_player

        @amount_of_asked_tricks = 0
        initialize_tricks_dicts
    end

    def is_trump?
        @is_trump
    end

    def ask_for_tricks(player, tricks_asked_by_player)
        validate_player_turn!(player)
        validate_asked_tricks_amount!(tricks_asked_by_player)
        @asked_tricks[player] = tricks_asked_by_player
        @amount_of_asked_tricks += tricks_asked_by_player
        advance_turn
    end

    def register_tricks(player, tricks_made_by_player)
        validate_all_players_have_asked_for_tricks!()
        validate_tricks_made_amount!(tricks_made_by_player)

        @tricks_made[player] = tricks_made_by_player

        if all_players_registered_tricks?
          calculate_points
          @game.next_round
        else
          advance_turn
        end
    end

    private

    def calculate_points
      # uses game.strategy to calculate points for each player
      for player in @game.players
        # Calculation logic here
      end
    end

    def advance_turn
        current_index = @game.players.index(@current_player)
        next_index = (current_index + 1) % @game.players.length
        @current_player = @game.players[next_index]
    end

    def all_players_registered_tricks?
        @tricks_made.keys.length == @game.players.length
    end

    def initialize_tricks_dicts
        @points = {}
        @asked_tricks = {}
        @tricks_made = {}

        @game.players.each do |player|
            @asked_tricks[player] = nil
            @tricks_made[player] = nil
        end
    end

    # region VALIDATIONS
    def validate_player_turn!(player)
        raise ArgumentError, "Wrong player turn. Expected #{@current_player}, got #{player}" unless player == @current_player
    end

    def validate_asked_tricks_amount!(tricks)
        if @amount_of_asked_tricks + tricks == @amount_of_cards
            raise ArgumentError, "Total asked tricks cannot equal the number of cards in the round"
        end
    end

    def validate_tricks_made_amount!(tricks_made)
        raise ArgumentError, "Invalid number of tricks made" unless tricks_made.between?(0, @amount_of_cards)
    end

    def validate_all_players_have_asked_for_tricks!
        raise ArgumentError, "Not all players have asked for tricks" unless @asked_tricks.values.all?
    end
    # endregion
end