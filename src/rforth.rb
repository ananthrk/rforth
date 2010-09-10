require 'pp'

module PrimitiveWords

  def dup
    @stack << @stack.last
  end

  def q_dup
    @stack << @stack.last unless @stack.last == 0 
  end

  def drop
    @stack.pop
  end

  def swap
    @stack += [@stack.pop, @stack.pop]
  end

  def over
    a = @stack.pop
    b = @stack.pop
    @stack << b << a << b
  end

  def rot
    a = @stack.pop
    b = @stack.pop
    c = @stack.pop
    @stack << b << a << c
  end

  def plus
    @stack << (@stack.pop + @stack.pop)
  end

  def mult
    @stack << (@stack.pop * @stack.pop) 
  end

  def subtract
    a = @stack.pop
    b = @stack.pop
    @stack << b - a
  end

  def divide
    a = @stack.pop
    b = @stack.pop
    @stack << b / a
  end

  def dot 
    @s_out.print( @stack.pop )
  end

  def cr
    @s_out.puts
  end

  def dot_s
    @s_out.print( "#{@stack}\n" )
  end

  def dot_d
    pp @dictionary
  end

end

class Dictionary
  def initialize( &block )
    @entries = {}
    block.call( self ) if block
  end

  def word( name, &block )
    @entries[name] = { :name => name, :block => block, :immediate => false }
    self
  end

  def immediate_word( name, &block )
    @entries[name] = { :name => name, :block => block, :immediate => true }
    self
  end

  def alias_word( name, old_name )
    entry = self[old_name]
    raise "No such word #{old_name}" unless entry
    new_entry = entry.dup
    new_entry[:name] = name
    @entries[name] = entry
  end

  def []( name )
    @entries[name]
  end
end

class RForth
  include PrimitiveWords

  def initialize( s_in = $stdin, s_out = $stdout )
    @s_in = s_in
    @s_out = s_out
    @dictionary = Dictionary.new
    @stack = []
    initialize_dictionary
  end

  # Create all of the initial words.
  def initialize_dictionary
    PrimitiveWords.public_instance_methods(false).each do |m|
      method_clojure = method(m.to_sym)
      word( m.to_s, &method_clojure )
    end

    alias_word( '?dup', 'q_dup' )
    alias_word( '+', 'plus' )
    alias_word( '*', 'mult' )
    alias_word( '-', 'subtract' )
    alias_word( '/', 'divide' )
    alias_word( '.', 'dot' )
    alias_word( '.S', 'dot_s' )
    alias_word( '.D', 'dot_d' )

    word(':')     { read_and_define_word }
    word('bye')   { exit }

    immediate_word( '\\' ) { @s_in.readline }
  end

  # Convience method that takes a word and a closure
  # and defines the word in the dictionary
  def word( name, &block )
    @dictionary.word( name, &block )
  end

  # Convience method that takes a word and a closure
  # and defines an immediate word in the dictionary
  def immediate_word( name, &block )
    @dictionary.immediate_word( name, &block )
  end

  # Convience method that takes an existing dict.
  # word and a new word and aliases the new word to
  # the old.
  def alias_word( name, old_name )
    @dictionary.alias_word( name, old_name )
  end

  # Given the name of a new words and the words
  # that make up its definition, define the
  # new word.
  def define_word( name, *words )
    @dictionary.word( name, &compile_words( *words ) )
  end

  # Give an array of (string) words, return
  # A block which will run all of those words.
  # Executes all immedate words, well, immediately.
  def compile_words( *words )
    blocks = []
    words.each do |word|
      entry = resolve_word( word )
      raise "no such word: #{word}" unless entry
      if entry[:immediate]
        entry[:block].call
      else
        blocks << entry[:block]
      end
    end
    proc do
      blocks.each {|b| b.call}
    end
  end

  # Read a word definition from input and
  # define the word
  # Definition looks like:
  #  new-word w1 w2 w3 ;
  def read_and_define_word
    name = read_word
    words = []
    while (word = read_word)
      break if word == ';'
      words << word
    end
    @dictionary.word(name, &compile_words( *words ))
  end

  # Given a (string) word, return the dictionary
  # entry for that word or nil.
  def resolve_word( word )
    return @dictionary[word] if @dictionary[word]
    x = to_number(word)
    if x
      block = proc { @stack << x }
      return { :name => word, :block => block, :immediate => false }
    end
    nil
  end

  # Evaluate the given word.
  def forth_eval( word )
    entry = resolve_word(word)
    if entry
      entry[:block].call
    else
      @s_out.puts "#{word} ??"
    end
  end

  # Try to turn the word into a number, return nil if
  # conversion fails
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

  def read_word
    result = nil
    ch = nil
    until @s_in.eof?
      ch = @s_in.readchar
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
