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
      @letter = l
      @digits = d
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
        
    attr_accessor :letters, :digits, :doon1, :firstcutter, :doon2, 
                  :extra_cutters, :year, :rest
    attr_accessor :original_string
    
                      
    def initialize(lead, fcset=nil, ec=[], year=nil, rest=nil)
      @letters = lead.letters
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
  
  
  
  