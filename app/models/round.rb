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

    def total_tricks_asked
        asked_tricks.values.compact.sum
    end

    def last_player_forbidden_value
        # if current player is last player
        if is_last_player?(@current_player) and not @asked_tricks.values.all?
            return @amount_of_cards - @amount_of_asked_tricks
        else
            return "-"
        end
    end

    def is_current_player(player)
        @current_player == player
    end

    def ask_for_tricks(player, tricks_asked_by_player)
        validate_player_turn!(player)
        validate_asked_tricks_amount!(player, tricks_asked_by_player)
        
        @asked_tricks[player] = tricks_asked_by_player
        @amount_of_asked_tricks += tricks_asked_by_player
        puts "Player #{player} asked for #{@asked_tricks[player]} tricks"
        advance_turn
    end

    def register_tricks(player, tricks_made_by_player)
        validate_all_players_have_asked_for_tricks!()
        validate_tricks_made_amount!(player, tricks_made_by_player)

        @tricks_made[player] = tricks_made_by_player
        puts "Player #{player} registered #{@tricks_made[player]} tricks"

        if all_players_registered_tricks?
          puts "All players have registered their tricks"
          calculate_points
          @game.next_round
        else
          advance_turn
        end
    end

    def to_json
        {
            round_number: @round_number,
            amount_of_cards: @amount_of_cards,
            current_player: @current_player,
            asked_tricks: @asked_tricks,
            tricks_made: @tricks_made,
            points: @points,
            starting_player: @starting_player
        }
    end

    def update_state(state)
        @current_player = state['current_player']
        @asked_tricks = state['asked_tricks']
        @tricks_made = state['tricks_made']
        @points = state['points']
    end

    private

    def calculate_points
      for player in @game.players
        @points[player] = @game.calculate_points(@asked_tricks[player], @tricks_made[player])
      end
    end

    def advance_turn
        current_index = @game.players.index(@current_player)
        next_index = (current_index + 1) % @game.players.length
        @current_player = @game.players[next_index]
        puts "Current player is now #{@current_player}"
    end

    def all_players_registered_tricks?
        @tricks_made.keys.length == @game.players.length and @tricks_made.values.all?
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
    def is_last_player?(player)
        starting_player_index = @game.players.index(@starting_player)
        last_player_index = starting_player_index - 1
        last_player = @game.players[last_player_index % @game.players.length]
        return player == last_player
    end

    def validate_player_turn!(player)
        raise ArgumentError, "Wrong player turn. Expected #{@current_player}, got #{player}" unless player == @current_player
    end

    def validate_asked_tricks_amount!(player, tricks_asked_by_player)
        if tricks_asked_by_player > @amount_of_cards
            puts "Total asked tricks cannot surpass number of cards in the round"
            raise ArgumentError, "Total asked tricks cannot surpass number of cards in the round"
        end
        if is_last_player?(player) and @amount_of_asked_tricks + tricks_asked_by_player == @amount_of_cards
            puts "Last player cannot ask for tricks if total sum equals amount of cards per round"
            raise ArgumentError, "Last player cannot ask for tricks if total sum equals amount of cards per round"
        end
    end

    def tricks_made_sum
        if @tricks_made.values.any?
            @tricks_made.values.compact.sum
        else
            0
        end
    end

    def validate_tricks_made_amount!(player, tricks_made)
        if is_last_player?(player) and tricks_made_sum + tricks_made != @amount_of_cards
            puts "Player #{player} registered #{tricks_made} tricks, but total sum is #{tricks_made_sum + tricks_made}"
            raise ArgumentError, "Last player must make the exact amount of tricks"
        elsif tricks_made_sum + tricks_made > @amount_of_cards
            raise ArgumentError, "Total tricks made cannot surpass number of cards in the round"
        elsif not tricks_made.between?(0, @amount_of_cards)
            raise ArgumentError, "Invalid number of tricks made"
        end
    end

    def validate_all_players_have_asked_for_tricks!
        # debug print statement
        if not @asked_tricks.values.all?
            puts "Not all players have asked for tricks"
            puts @asked_tricks.inspect
        end


        raise ArgumentError, "Not all players have asked for tricks" unless @asked_tricks.values.all?
    end
    # endregion
end

class NullRound
    attr_reader :round_number
    def initialize
        @round_number = 0
    end

    def ask_for_tricks(player, tricks)
    end

    def register_tricks(player, tricks)
    end

    def total_tricks_asked
        0
    end

    def last_player_forbidden_value
        "-"
    end

    def to_json
        {
            round_number: @round_number,
            amount_of_cards: 0,
            current_player: "",
            asked_tricks: {},
            tricks_made: {},
            points: {},
            starting_player: ""
        }
    end

end