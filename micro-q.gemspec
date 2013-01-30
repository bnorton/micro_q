# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'micro-q/version'

Gem::Specification.new do |gem|
  gem.name          = "micro-q"
  gem.version       = Micro::Q::VERSION
  gem.authors       = ["Brian Norton"]
  gem.email         = ["brian.nort@gmail.com"]
  gem.description   = ""
  gem.summary       = ""
  gem.homepage      = "http://github/com/bnorton/micro-q"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^spec/})
  gem.require_paths = ["lib"]

  gem.add_dependency             "celluloid"
  gem.add_development_dependency "rspec"
end
