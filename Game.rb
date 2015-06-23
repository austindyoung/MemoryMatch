class Game

  attr_accessor :board, :prev_pick, :curr_pick, :guess_count, :max_guesses, :size

  def initialize
    @board = Board.new(set_difficulty)
    @prev_pick = nil
    @curr_pick = nil
    @guess_count = 0
    @size = @board.size
    @max_guesses = 3 * @size ** 2
    @ERROR_HASH = {
      :syntax => "Invalid Syntax.",
      :range => "Position out of range",
      :matched => "Card already matched",
      :visible => "Same card"
    }
    @VALIDATOR_HASH = generate_validator_hash
  end

  def generate_validator_hash
    hash = {}
    hash[:syntax] = Proc.new { |input| input.match(/\A\d+,\d+\Z/) }
    hash[:range] = Proc.new { |input| parse(input).all? { |value| (0...size).cover?(value.to_i) } }
    hash[:matched] = Proc.new { |input| board[*parse(input)] != :matched}
    hash[:visible] = Proc.new { |input| board[*parse(input)].visible == false}
    hash
  end

  def set_difficulty
    puts "Standard Game? (y/n)"
    raw_input = gets.chomp
    if raw_input == 'y'
      6
    else
      puts "What size board? (2-10)"
      gets.chomp.to_i
    end
  end

  def play
    until over?
      display_board
      first_pick
      display_board
      second_pick
      display_board
      sleep(1)
      update_board
      @guess_count += 1
    end
    if guess_count == max_guesses
      puts "You lose."
    else
      puts "You won in #{guess_count} picks."
    end
  end

  def first_pick
      @prev_pick = player_pick
      board[*prev_pick].show
  end

  def second_pick
    @curr_pick = player_pick
    board[*curr_pick].show
  end

  def update_board
    if board[*prev_pick] == board[*curr_pick]
      board[*prev_pick] = :matched
      board[*curr_pick] = :matched
    else
      board[*prev_pick].hide
      board[*curr_pick].hide
    end
  end

  def match?(card1, card2)
    card1 == card2
  end

  def over?
    guess_count == max_guesses || board.map(&:uniq).uniq == [[:matched]]
  end

  def player_pick
    parse(get_pick)
  end

  def parse(response)
    #form, eg: 1,2
    response.split(",").map(&:to_i)
  end

  def get_pick
    puts "Choose a card (e.g. 1,2)"
    raw_input = gets.chomp

    until valid_input?(raw_input)
      raw_input = gets.chomp
    end
    raw_input
  end

  def valid_input?(input)
      @VALIDATOR_HASH.keys.each do |error_type|
        if !@VALIDATOR_HASH[error_type].call(input)
          puts @ERROR_HASH[error_type]
          return false
        end
      end
      true
  end

  def display_board
    system("clear")
    @board.each do |row|
      puts row.map { |card| display_card(card) }.join(" ")
    end
  end

  def display_card(card)
    if card == :matched
      "."
    elsif card.visible
      card.content
    else
      "X"
    end
  end
end

class Board

  attr_accessor :grid, :size
  include Enumerable

  def initialize(size)
    @size = size
    @grid = populated_grid(size)
  end

  def populated_grid(size)
    alphabet = ('a'..'z').to_a + ('A'..'Z').to_a - ['X']
    values = ((0...size ** 2 / 2).to_a * 2).shuffle.map { |idx| alphabet[idx] }
    Array.new(size) {Array.new(size) {Card.new(values.pop)}}
  end

  def [](row, col)
    grid[row][col]
  end

  def []=(row, col, value)
    grid[row][col] = value
  end

  def each
    grid.each { |row| yield(row) }
  end
end

class Card

  attr_accessor :visible, :content

  def initialize(content)
    @visible = false
    @content = content
  end

  def hide
    @visible = false
  end

  def show
    @visible = true
  end


  def ==(other_card)
    return false unless other_card.class == Card
    content == other_card.content
  end

end

Game.new.play
=begin
g = Game.new
g.board[2,3] = :matched
g.board[1,2].show
g.display_board
=end
