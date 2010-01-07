#!/usr/bin/ruby

# enc.rb                                                                   [fs]
#   encode german ascii text into tengwarscript LaTeX directives
#
# Kopyleft (K) 2009 - All Rites Reversed 

require "yaml"

class Map
  
  def initialize
    File.open("map.yaml") do |yf|
      map = YAML::load(yf)
      
      @letters = map["letters"]
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
    
    for i in 0..(letters.length - 1)
      last_letter = nil
      unless i == 0
        last_letter = letters[i - 1]
      end
      this_letter = letters[i]
      next_letter = nil
      unless i == (letters.length - 1)
        next_letter = letters[i + 1]
      end
      
      if last_letter == this_letter    # doubler
        next
      end
      
      if this_letter == "n" and next_letter =~ /[^aeiou\.]/    # nasal
        next
      end

      
      if this_letter =~ /^[aeiou]$/    # standalone vocal
        if last_letter == nil or last_letter =~ /[aeiou]/
          result << "\\Ttelco"
        end
      end
      
      if this_letter == "s" and next_letter =~ /[aeiou]/    # silme nuquerna
        result << "\\Tsilmenuquerna"
      elsif this_letter == "ss" and next_letter =~ /[aeiou]/    # esse nuquerna
        result << "\\Tessenuquerna"
      elsif this_letter == "r" and next_letter =~ /[aeiou]/    # romen
        result << "\\Troomen"
      else
        result << @letters[letters[i]]   # normal
      end
      
      if this_letter == next_letter    # doubler
        result << "\\TTdoubler"
      end
      
      if last_letter == "n" and this_letter =~ /[^aeiou\.]/    # nasal
        result << "\\TTnasalizer"
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

