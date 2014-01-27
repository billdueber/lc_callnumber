require 'parslet'
require 'lc_callnumber/lcc'

module LCCallNumber
  class Parser < Parslet::Parser
    rule(:space)  { match('\s').repeat(1) }
    rule(:space?) { space.maybe }
    rule(:dot)    { str('.') }
    rule(:dot?)   { dot.maybe }
    
    rule(:digit)  { match('\d') }
    rule(:digits) { digit.repeat(1) }
    rule(:digits?) { digits.maybe }
    
    rule(:year) { digits }
    
    rule(:firstletter) { match('(?i:[A-HJ-NP-VZ])') }
    rule(:letter) { match('(?i:[A-Z])') }
    rule(:a2) { firstletter >> letter.maybe }
    rule(:a3) { 
      match['K'] >> letter.repeat(2) |
      str('DAW') |
      str('DJK')
    }
    
    rule(:alpha) {
      a3 | 
      a2
    }
    
    # Numeric string may or may not have a dot
    rule(:numstring) {
      digits.as(:intpart) >> (dot >> digits.as(:fractpart)).maybe 
    }
    
    # So, the "lead" is what I'm calling the necessary part of the callnumber,
    # the letter(s) and following number
    rule(:lead) {
      (alpha.as(:alpha) >> space? >> numstring.as(:numbers)).as(:lead) 
      #|
      #(alpha.as(:alpha) >> space).as(:lead)
    }
    
    
    # "Date or other number" -- need to take into account 1st, 2nd, etc.
    # Should probably restrict this so that, e.g., you can't have "2rd"
    # but for now this is sufficient.
    rule(:suffix) {
      str('ST') |
      str('ND') |
      str('RD') | 
      str('TH')
    }
    
    rule(:doon) {
      dot? >> digits.as(:digits) >> space? >> suffix.as(:suffix) |
      digits.as(:digits)
    }
    rule(:doon?) { doon.maybe }
      
    # Cutter is a letter followed by numbers
    rule(:dotcutter) { (dot.as(:dot) >> letter.as(:letter) >> digits.as(:digits)).as(:cutter) }
    rule(:odotcutter) { ((dot.maybe).as(:dot) >> letter.as(:letter) >> digits.as(:digits)).as(:cutter) }
    
    # # Firstcutter has to have a dot
    # rule(:dotcutter) { dot >> cutter }
    # rule(:odotcutter) { (dot.maybe).as(:dot) >> cutter}
    
    # The first cutter set can have doons on either side
    rule(:firstcutterset) {
      ((doon >> space).maybe).as(:doon1) >> odotcutter.as(:cutter) >> ((space >>  doon).maybe).as(:doon2)
    }
   
    # Other cutters may or may not have a dot
    rule(:extracutters) {
      (space? >> odotcutter).repeat(0)
    }
    
    rule(:cutters) {
      odotcutter >> extracutters
    }
   
    # The rest of it, if there is anything but spaces
    rule(:rest) {
      space? >> any.repeat(1)
    }

    rule(:lcclass) {
      lead >> space? >> (firstcutterset).as(:fcset) >> extracutters.as(:ec) >> ((space >>  year.as(:yeardigits)).maybe).as(:year) >> (rest.maybe).as(:rest) | 
      lead >> ((space >>  year.as(:yeardigits)).maybe).as(:year) >> (rest.maybe).as(:rest)
    }
    root(:lcclass)
  end
  
  
  
  class Transform < Parslet::Transform
    rule(:intpart=>simple(:i), :fractpart=>simple(:f)) { Decimal.new(i,f) }
    rule(:intpart=>simple(:i)) { Decimal.new(i,nil) }
    
    rule(:alpha=>simple(:a), :numbers=>simple(:n)) { @a = Lead.new(a,n) }
    rule(:digits=>simple(:d), :suffix=>simple(:s)) {"#{d}#{s}"}
    rule(:digits=>simple(:d)) { d.to_s }
    rule(:doon => simple(:d)) { d.strip }
    rule(:cutter => {:dot=>simple(:dot), :letter=>simple(:l), :digits=>simple(:d)}) { Cutter.new(l,d, dot)}
    
    rule(:doon1=>simple(:d1), :doon2=>simple(:d2), :cutter=>simple(:c)) { FirstCutterSet.new(d1, c, d2)}
    rule(:yeardigits => simple(:y)) { y.nil? ? nil : y.to_s.strip}
    rule(:lead=>simple(:l), :fcset=>simple(:fc), :ec=>sequence(:ec), :year=>simple(:year), :rest=>simple(:rest)) { CallNumber.new(l,fc,ec,year,rest.to_s)}
    rule(:lead=>simple(:l), :year=>simple(:year), :rest=>simple(:rest)) {CallNumber.new(l,nil,[],year,rest.to_s)}
  end
  
end
