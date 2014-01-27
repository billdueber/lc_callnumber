# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lc_callnumber/version'

Gem::Specification.new do |spec|
  spec.name          = "lc_callnumber"
  spec.version       = LCCallNumber::VERSION
  spec.authors       = ["Bill Dueber"]
  spec.email         = ["bill@dueber.com"]
  spec.description   = %q{Work with  LC Call (Classification) Numbers}
  spec.summary       = %q{Work with  LC Call (Classification) Numbers, including an attempt to parse them out from a string to their component parts}
  spec.homepage      = "https://github.com/billdueber/lc_callnumber"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'parslet'
  
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
end
