class Round
    attr_reader :round_number, :amount_of_cards, :amount_of_asked_tricks,
                :asked_tricks, :current_player, :tricks_made, :points

    def initialize(game, round_number, amount_of_cards, is_trump, starting_player)
        @game = game
        @round_number = round_number
        @amount_of_cards = amount_of_cards
        @is_trump = is_trump
        @starting_player = starting_player
        @current_player = starting_player

        @amount_of_asked_tricks = 0
        @asked_tricks = {}
        @tricks_made = {}
    end

    def is_trump?
        @is_trump
    end

    def ask_for_tricks(player, tricks_asked_by_player)
        validate_player_turn!(player)
        validate_asked_tricks_amount!(tricks_asked_by_player)
        advance_turn

        @amount_of_asked_tricks += tricks_asked_by_player
        @asked_tricks[player] = tricks_asked_by_player
    end

    def register_tricks(player, tricks_made_by_player)
        validate_all_players_have_asked_for_tricks!()
        validate_tricks_made_amount!(tricks_made_by_player)

        @tricks_made[player] = tricks_made_by_player

        if is_last_player?
          calculate_points
        end
    end

    private

    def calculate_points
      # uses game.strategy to calculate points for each player
      @points = {}
      for player in @asked_tricks.keys
        @points[player] = @game.calculate_points(@asked_tricks[player], @tricks_made[player])
      end
    end
   

    def advance_turn
        @current_player = @game.next_player_to(@current_player)
    end

    def is_last_player?
        @tricks_made.keys.length == @game.players.length
    end

    # region VALIDATIONS
    def validate_player_turn!(player)
        raise ArgumentError, "Wrong player turn. Expected #{@current_player}, got #{player}" unless player == @current_player
    end

    def validate_asked_tricks_amount!(tricks)
        if @amount_of_asked_tricks + tricks == @amount_of_cards
            raise ArgumentError, "Last player cannot ask for tricks if total sum equals amount of cards per round"
        end
    end

    def validate_tricks_made_amount!(tricks_made)
        raise ArgumentError, "Invalid amount of tricks made by that player" unless tricks_made.between?(0, @amount_of_cards)
    end

    def validate_all_players_have_asked_for_tricks!
        raise ArgumentError, "Cannot register tricks if all players have not asked for tricks" unless @asked_tricks.keys.length == @game.players.length
    end

    # endregion
end