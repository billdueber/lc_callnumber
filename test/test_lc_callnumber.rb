require 'minitest_helper'

describe "Metadata" do
  it "has a version number" do
     assert ::LCCallNumber::VERSION
  end
end

describe "Basics" do
  it "can parse all the items in the basics file" do
    File.open(test_data('basics.txt')).each_line do |line|
      next if line =~ /\A#/
      next unless line =~ /\S/
      line.chomp!
      orig,letters,digits,doon1,c1,doon2,other_cutters,pubyear,rest = line.split(/\t/).map{|s| s.upcase.strip.to_s}
      lc = LCCallNumber.parse(orig)
      assert_equal letters.to_s, lc.letters, "#{orig} -> letters #{lc.inspect}"
      assert_equal digits.to_s, lc.digits.to_s, "#{orig} -> numbers #{lc.inspect}"
      assert_equal doon1.to_s, lc.doon1.to_s, "#{orig} -> doon1 #{lc.inspect}"
      assert_equal c1.to_s, lc.firstcutter.to_s, "#{orig} -> first cutter #{lc.inspect}"
      assert_equal doon2.to_s, lc.doon2.to_s, "#{orig} -> doon2 #{lc.inspect}"
      assert_equal other_cutters.to_s.split(/\s*,\s*/), lc.extra_cutters.map(&:to_s), "#{orig} -> extra_cutters #{lc.inspect}"
      assert_equal pubyear.to_s, lc.year.to_s,  "#{orig} -> year #{lc.inspect}"
      assert_equal rest.to_s, lc.rest.to_s,  "#{orig} -> rest #{lc.inspect}"
      
    end
    
  end
end
      
      
      
