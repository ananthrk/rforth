require 'pp'

class Dictionary
  def initialize
    @entries = {}
  end

  def word( name, &block )
    @entries[name] = { :name => name, :block => block, :immediate => false }
  end

  def immediate_word( name, &block )
    @entries[name] = { :name => name, :block => block, :immediate => true }
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
    d = Dictionary.new
    
    # stack management
    d.word('dup')   { @stack << @stack.last }
    d.word('?dup')  { @stack << @stack.last unless @stack.last == 0 }
    d.word('drop')  { @stack.pop }
    d.word('swap') do
      a = @stack.pop
      b = @stack.pop
      @stack << a << b
    end
    d.word('over') do
      a = @stack.pop
      b = @stack.pop
      @stack << b << a << b
    end
    d.word('rot') do
      a = @stack.pop
      b = @stack.pop
      c = @stack.pop
      @stack << b << a << c
    end

    # quotations
    d.word(':')     { define_word }

    # math
    d.word('+')     { @stack << (@stack.pop + @stack.pop) }
    d.word('*')     { @stack << (@stack.pop * @stack.pop) }
    d.word('-') do
      a = @stack.pop
      b = @stack.pop
      @stack << b - a
    end

    d.word('/') do
      a = @stack.pop
      b = @stack.pop
      @stack << b / a
    end

    # aux words
    d.word('.')     { @s_out.print( "#{@stack.pop}\n" ) }
    d.word('.S')    { @s_out.print( "#{@stack}\n" ) }
    d.word('cr')    { @s_out.puts }
    d.word('bye')   { exit }

    d
  end

  def define_word
    name = read_word
    blocks = []
    while (word = read_word)
      break if word == ';'
      entry = @dictionary.word(word)
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
