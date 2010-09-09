require 'pp'

class Dictionary
  def initialize
    @entries = {}
  end

  def word( name, &block )
    @entries[name] = { :name => name, :block => block, :immediate => false }
    self
  end

  def immediate_word( name, &block )
    @entries[name] = { :name => name, :block => block, :immediate => true }
    self
  end

  def []( name )
    @entries[name]
  end
end

class RForth

  def initialize( s_in = $stdin, s_out = $stdout )
    @s_in = s_in
    @s_out = s_out
    @dictionary = initial_dictionary
    @stack = []
  end

  def initial_dictionary
    Dictionary.new
    .word('dup')   { @stack << @stack.last }
    .word('?dup')  { @stack << @stack.last unless @stack.last == 0 }
    .word('drop')  { @stack.pop }
    .word('swap')  { @stack += [@stack.pop, @stack.pop] }
    .word('over') do
      a = @stack.pop
      b = @stack.pop
      @stack << b << a << b
    end
    .word('rot') do
      a = @stack.pop
      b = @stack.pop
      c = @stack.pop
      @stack << b << a << c
    end
    .word(':')     { define_word }
    .word('+')     { @stack << (@stack.pop + @stack.pop) }
    .word('*')     { @stack << (@stack.pop * @stack.pop) }
    .word('-') do
      a = @stack.pop
      b = @stack.pop
      @stack << b - a
    end
    .word('/') do
      a = @stack.pop
      b = @stack.pop
      @stack << b / a
    end
    .word('.')     { @s_out.print( "#{@stack.pop}\n" ) }
    .word('.S')    { @s_out.print( "#{@stack}\n" ) }
    .word('.D')    { pp @dictionary }
    .word('cr')    { @s_out.puts }
    .word('bye')   { exit }
  end

  def define_word
    name = read_word
    blocks = []
    while (word = read_word)
      break if word == ';'
      entry = @dictionary[word]
      raise "no such word: #{word}" unless entry
      if entry[:immediate]
        entry[:block].call
      else
        blocks << entry[:block]
      end
    end

    @dictionary.word(name) do
      blocks.each {|b| b.call}
    end
  end

  def forth_eval( word )
    if @dictionary[word]
      @dictionary[word][:block].call
    elsif (x = to_number(word))
      @stack << x
    else
      @s_out.puts "#{word} ??"
    end
  end

  def to_number( word )
    begin
      return Integer( word )
    rescue
      puts $!
    end
    begin
      return Float( word )
    rescue
      puts $!
    end
    nil
  end

  def read_char
    @s_in.readchar
  end

  def read_word
    result = nil
    ch = nil
    until @s_in.eof?
      ch = read_char
      if result and is_space?(ch)
        break
      elsif result.nil?
        result = ch
      else
        result << ch
      end
    end
    return result if result
    nil
  end

  def is_space?( ch )
    /\W/ =~ ch.chr
  end

  def run
    until $stdin.eof?
      @s_out.flush
      word = read_word
      forth_eval( word )
    end
  end
end

RForth.new.run 
