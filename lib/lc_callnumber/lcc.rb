require 'lc_callnumber/parser'

module LCCallNumber

  @parser = Parser.new
  @transformer = Transform.new

  def self.parse(i)
    return UnparseableCallNumber.new(i) if i.nil?
    i.chomp!
    i.strip!
    orig = i
    i.gsub!(/\[(.+)\]/, "$1")
    i.gsub!('\\', ' ')

    # We also have a bunch that start with a slash and have slashes where you'd
    # expect logical breaks. Don't know why.

    if i =~ /\A\//
      i.gsub!('/', ' ')
    end

    # Ditch leading + or *
    i.gsub!(/\A[+*]/, '')

    # Strip off any leading/trailing spaces and upcase it
    i.strip!
    i.upcase!

    # Don't bother if it starts with a number, four letters, or the string 'law'
    # Don't bother if there's no numbers at all
    if (/\A\d/.match i) or
       (/\A[[:alpha:]]{4}/.match i) or
       (/\ALAW/i.match i) or
       !(/\d/.match i)
       return UnparseableCallNumber.new(orig)
    end

    begin
      p = @parser.parse(i)
      # puts p
      lc = @transformer.apply(p)
      lc.original_string = orig
      return lc
    rescue Parslet::ParseFailed => e
      return UnparseableCallNumber.new(orig)
    end
  end







  # The "lead" -- initial letter(s) and digit(s)
  class Lead
    attr_accessor :letters, :digits
    def initialize(l, d)
      @letters = l
      @digits = d
    end
    def inspect
      "Lead<#{letters}, #{digits.inspect}>"
    end
  end

  # A generic "Decimal" part, where we keep the
  # integer and fractional parts separate so
  # we can construct a string more easily

  class Decimal
    attr_accessor :intpart, :fractpart
    def initialize(i, f=nil)
      @intpart = i
      @fractpart = f
    end

    def to_num
      fractpart ? "#{intpart}.#{fractpart}".to_f : intpart.to_i
    end

    def to_s
      fractpart ? "#{intpart}.#{fractpart}" : intpart
    end


    def inspect
      if fractpart
        "#{intpart}:#{fractpart}"
      else
        "#{intpart}"
      end
    end
  end

  # A "Cutter" is a single letter followed by one or more digits
  # It is sometimes preceded by a decimal point. We note whether or not
  # we got a decimal point because it may be a hint as to whether or not
  # we're actually looking at a Cutter.

  class Cutter
    attr_accessor :letter, :digits, :dot
    def initialize(l,d, dot=nil)
      @letter = l.to_s
      @digits = d.to_i
      @dot = !dot.nil?
    end

    def inspect
      "Cut<#{letter},#{digits}>"
    end

    def to_s
      "#{letter}#{digits}"
    end
  end


  # Some call numbers have a year, infantry division, etc. preceeding
  # and/or following the first cutter. We take all three as a unit so
  # we can deal with edge cases more easily.
  #
  # "doon" in this case is "Date Or Other Number"

  class FirstCutterSet
    attr_accessor :doon1, :cutter, :doon2
    def initialize(d1, cutter, d2)
      @doon1 = d1
      @doon2 = d2
      @cutter = cutter
    end
  end

  # Bring it all together in the callnumber
  # We feed it the parts we have, and then reassign fields based on
  # what we have.
  #
  # To wit:
  #  Q123 .C4 1990 --- published in 1990
  #  Q123 .C4 1990 .D5 2003 -- published in 2003 with a 2nd doon of 1990


  class CallNumber

    include Comparable
    attr_accessor :letters, :digits, :doon1, :firstcutter, :doon2,
                  :extra_cutters, :year, :rest
    attr_accessor :original_string


    def initialize(lead, fcset=nil, ec=[], year=nil, rest=nil)
      @letters = lead.letters.to_s.upcase
      @digits  = lead.digits.to_num

      if fcset
        @doon1   = fcset.doon1
        @doon2   = fcset.doon2
        @firstcutter = fcset.cutter
      end

      @extra_cutters = ec
      @year = year
      @rest = rest

      @rest.strip! if @rest

      self.reassign_fields
    end

    def reassign_fields
      # If we've got a doon2,  but no year and no extra cutters,
      # put the doon2 in the year

      if doon2 and (doon2=~ /\A\d+\Z/) and extra_cutters.empty? and year.nil?
        @year = @doon2
        @doon2 = nil
      end
    end

    def inspect
      header = %w(letters digits doon1 cut1 doon2 othercut)
      actual = [letters,digits,doon1,firstcutter,doon2,extra_cutters.join(','),year,rest].map{|x| x.to_s}
      fmt = '%-7s %-9s %-6s %-6s %-6s %-20s year=%-6s rest=%-s'
      [('%-7s %-9s %-6s %-6s %-6s %-s' % header), (fmt % actual)].join("\n")

    end


    def valid?
      @letters && @digits
    end

    def <=>(other)
      # Make call numbers sortable.
      # Work through the various parts, from left to right.
      # (They compare as strings or numbers as appropriate, thanks to the above.)

      letters_cmp = letters <=> other.letters
      return letters_cmp unless letters_cmp == 0

      digits_cmp = digits <=> other.digits
      return digits_cmp unless digits_cmp == 0

      doon1_cmp = doon1 <=> other.doon1
      return doon1_cmp unless doon1_cmp == 0

      # Cutters have letters and numbers, which we need to compare separately.
      if firstcutter
        if other.firstcutter
          # Both have firstcutters!  Hurrah!
          # Compare the letter
          firstcutter_cmp = firstcutter.letter <=> other.firstcutter.letter
          # If that didn't help, compare the digits
          if firstcutter_cmp == 0
            # Compare numbers as strings, because S43 < S298
            firstcutter_cmp = firstcutter.digits.to_s <=> other.firstcutter.digits.to_s
          end
          # If that didn't help, if other has an extra_cutter, it is last
          if firstcutter_cmp == 0
            firstcutter_cmp = -1 if (extra_cutters.empty? && ! other.extra_cutters.empty?)
          end
        else
          # self has a firstcutter but other doesn't, so other is first
          firstcutter_cmp = 1
        end
      else
        # self has no firstcutter
        if other.firstcutter
          # other does, so it comes last
          firstcutter_cmp = -1
        else
          # Neither has one, so carry on
          firstcutter_cmp = 0
        end
      end
      return firstcutter_cmp unless firstcutter_cmp == 0

      doon2_cmp = doon2 <=> other.doon2
      return doon2_cmp unless doon2_cmp == 0

      # The extra_cutters are an array, so we need to compare each.
      # Surely there is an easier way to do this?
      extra_cutters_cmp = 0
      # STDERR.puts extra_cutters
      extra_cutters.each_index do |i|
        if extra_cutters_cmp == 0 # Stop when we need go no further
          # First, compare the letter
          if other.extra_cutters[i]
            extra_cutters_cmp = extra_cutters[i].letter <=> other.extra_cutters[i].letter
            # If that didn't help, compare the digits
            if extra_cutters_cmp == 0
              # Compare numbers as strings, because S43 < S298
              extra_cutters_cmp = extra_cutters[i].digits.to_s <=> other.extra_cutters[i].digits.to_s
            end
            # If that didn't help, if self has no more extra_cutters but other does, self is first
            if extra_cutters_cmp == 0
              extra_cutters_cmp = -1 if (extra_cutters[i+1].nil? && other.extra_cutters[i+1])
            end
          else
            # other has no extra_cutter, so it is first
            extra_cutters_cmp = 1
          end
        end
      end
      return extra_cutters_cmp unless extra_cutters_cmp == 0

      year_cmp = year <=> other.year
      return year_cmp unless year_cmp == 0

      rest_cmp = rest <=> other.rest
      return rest_cmp

    end

  end

  class UnparseableCallNumber < CallNumber

    def initialize(str)
      self.original_string = str
      self.extra_cutters = []
    end

    def valid?
      false
    end

  end



end
