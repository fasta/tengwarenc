#!/usr/bin/ruby

# enc.rb                                                                   [fs]
#   encode german ascii text into tengwarscript LaTeX directives
#
# Kopyleft (K) 2009 - All Rites Reversed 

require "jcode"    # fix 'String.each_char' for ruby 1.8

require "yaml"

class Condition
  attr_accessor :last, :this, :next
  attr_accessor :letter

  def resolve(last_letter, this_letter, next_letter)
    if (@last and @last.include? "@@") or
       (@this and @this.include? "@@") or
       (@next and @next.include? "@@")
      
      condition = Condition.new

      condition.last = @last
      if @last and @last.include? "@@"
        condition.last = eval @last[2..-1], binding
      end
      condition.this = @this
      if @this and @this.include? "@@"
        condition.this = eval @this[2..-1], binding
      end
      condition.next = @next
      if @next and @next.include? "@@"
        condition.next = eval @next[2..-1], binding
      end
 
      return condition
    else
      return self
    end
  end

  def match?(last_l, this_l, next_l)
    condition = self.resolve last_l, this_l, next_l

    unless last_l =~ /#{condition.last}/
      return false
    end

    unless this_l =~ /#{condition.this}/
      return false
    end

    unless next_l =~ /#{condition.next}/
      return false
    end

    return true
  end

end

class Map
  
  def initialize
    File.open("map.yaml") do |yf|
      map = YAML::load(yf)
      
      @letters = map["letters"]
      @append_rules = map["append"]
      @insert_rules = map["insert"]
      @replace_rules = map["replace"]
    end
  end
  
  def letters(word)
    letters = Array.new
    
    separated = false
    @letters.keys.sort_by { |k| -k.length }.each do |letter|
      if letter.length == 1
        break
      end
      
      pos = word.index letter
      if pos
        unless pos == 0
          letters(word[0..(pos - 1)]).each do |element|
            letters << element
          end
        end
        letters <<  letter
        pos += letter.length
        unless pos == word.length
          letters(word[pos..word.length]).each do |element|
            letters << element
          end
        end
        separated = true
        break
      end
    end
    
    unless separated
      word.each_char do |c|
        letters << c
      end
    end
    
    return letters
  end
  
  def encode(letters)
    result = Array.new
    
    append_letter = nil
    for i in 0..(letters.length - 1)
      last_letter = ""
      unless i == 0
        last_letter = letters[i - 1]
      end
      this_letter = letters[i]
      next_letter = ""
      unless i == (letters.length - 1)
        next_letter = letters[i + 1]
      end

      append = nil
      @append_rules.each do |condition|
        if condition.match? last_letter, this_letter, next_letter
          append = condition.letter
          break    # multiple conditions?
        end
      end
      # append to next letter
      if append
        append_letter = append
        next
      end

      @insert_rules.each do |condition|
        if condition.match? last_letter, this_letter, next_letter
          result << condition.letter
          break    # multiple conditions?
        end
      end
      
      replace_letter = nil
      @replace_rules.each do |condition|
        if condition.match? last_letter, this_letter, next_letter
          replace_letter = condition.letter
        end
      end

      unless replace_letter
        result << @letters[letters[i]]   # normal
      else
        result << replace_letter
        replace_letter = nil
      end

      if append_letter
        result << append_letter
        append_letter = nil
      end
    end
    
    return result
  end
  
end

# main
#
mapping = Map.new

input = File.open "in", "r"
input.each do |line|
  line.each(" ") do |word|
    word.downcase!
    word.strip!
    
    # separate word elements
    letters = mapping.letters(word)
    
    letters.each do |letter|
      $stderr.print "[#{letter}]"
    end
    $stderr.print "\n"
    
    # encode word elments
    result = mapping.encode(letters)
    
    result.each do |e|
      $stderr.print "(#{e})"
    end
    $stderr.print "\n"
    
    # print word
    print result.join
    print " \\Tcentereddot "
    
  end
  print "\\\\\n"
end

