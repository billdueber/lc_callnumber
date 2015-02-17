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

describe "Sorting" do
  a1 = LCCallNumber.parse("A 50")
  a2 = LCCallNumber.parse("A 7")
  b1 = LCCallNumber.parse("B 528.S43")
  b2 = LCCallNumber.parse("B 528.S298")
  q1 = LCCallNumber.parse("QA 500")
  q2 = LCCallNumber.parse("QA 500.M500")
  q3 = LCCallNumber.parse("QA 500.M500 T59")
  q4 = LCCallNumber.parse("QA 500.M500 T60")
  q5 = LCCallNumber.parse("QA 500.M500 T60 A1")
  q6 = LCCallNumber.parse("QA 500.M500 T60 Z54")
  it "knows call numbers equal themselves" do
    assert (a1 <=> a1) ==  0 # A == A (very Aristotelian)
  end
  it "sorts first letters properly" do
    assert (a2 <=> q1) == -1 # A < Q
  end
  it "sorts first digits properly" do
    assert (a1 <=> a2) ==  1 # A 50 > A 7
  end
  it "sorts when one item has no Cutter" do
    assert (q1 <=> q2) == -1 # QA 500 < QA 500.M500
  end
  it "sorts first Cutters properly" do
    assert (b1 <=> b2) ==  1 # S43 > S298
  end
  it "sorts when one item has a Cutter, one an extra Cutter" do
    assert (q2 <=> q3) == -1 # M500 < M500 T59
  end
  it "sorts properly on second Cutters" do
    assert (q3 <=> q4) == -1 # T59 < T60
  end
  it "sorts when one item has two Cutters, one has three" do
    assert (q4 <=> q5) == -1 # M500 T60 < M500 T60 A1
  end
  it "sorts properly on third Cutters" do
    assert (q5 <=> q6) == -1 # A1 < Z54
  end
end
