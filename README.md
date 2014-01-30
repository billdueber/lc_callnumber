[![Build Status](https://secure.travis-ci.org/billdueber/lc_callnumber.png)](http://travis-ci.org/billdueber/lc_callnumber)

# LCCallNumber

Very simple attempt to work with Library of Congress Call Numbers (_nee_ Classification Numbers).
Includes simple getters/setters and a PEG parser.


## Things that aren't yet done

* Normalization: create a string that can be compared with other normalized strings to correctly order the call numbers
* Implement `<=>` so call number object can be compared.
* Much better testing


## Parts of an LC Call Number

LC Call Numbers are used in libraries to classify and order books and other items.

Some (increasingly complex) samples are:

* A1
* A1.2 .B3
* A1.2 .B3 .C4
* A1.2 .B3 1990
* A1.2 1888 .B3 .C4 2000
* A1.2 .A54 21st 2010

The OCLC has [a page explaining how LC Call Numbers are composed](http://www.oclc.org/bibformats/en/0xx/050.html), which you should reference if you feel the need.

For purposes of this class, an LC Call Number consists of the following parts. Only the first two are required; everything else is optional.

* __Letter(s).__ One or more letters
* __Digit(s).__ One or more digits, optionally with a decimal point. 
* __Doon1 (_Date Or Other Number_)__. Relatively rare as these things go, a DOON is used to represent the date the work is _about_ (as opposed to, say, the year it was published) or, in some cases, an identifier for an army division or group (say, "12th" for the US Army Twelfth Infantry). 
* __First cutter__. The first "Cutter Number" consisting of a letter followed by one or more digits. The first cutter is always supposed to be preceded by a dot, but, you know, isn't always.
* __Doon2__. Another date or other number
* __"Extra" Cutters__. The 2nd through Nth Cutter numbers, lumped together because we don't have to worry about them getting interspersed with doons.
* __Year__. The year of publication
* __"Rest"__. Everything and anything else. 

## Usage

In general, you won't be building these things up by hand; you'll try to parse them.

Note that in the case below, while in theory this could be a callnumber with a single cutter followed by a doon2 and no year, we presume the '1990' is a year and don't call it a doon.

~~~ruby

require 'lc_callnumber'

lc = LCCallNumber.parse('A1.2 .B3 1990') #=> LCCallNumber::CallNumber
lc.letters #=> 'A'
lc.digits  #=> 1.2 (as a float for a float; int if there's no decimal)
lc.doon1   #=> nil
lc.firstcutter #=> Cutter<letter=>'B', digits=>'3', dot=>true>
lc.extra_cutters #=> []
lc.year      #=> 1990
lc.rest      #=> nil

lc = LCCallNumber.parse('A .B3') #=> LCCallNumber::UnparseableCallNumber
lc.valid? #=> false

~~~


## Installation

Add this line to your application's Gemfile:

    gem 'lc_callnumber'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install lc_callnumber





## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
