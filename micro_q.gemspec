# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'micro_q/version'

Gem::Specification.new do |gem|
  gem.name          = "micro_q"
  gem.version       = MicroQ::VERSION
  gem.authors       = ["Brian Norton"]
  gem.email         = ["brian.nort@gmail.com"]
  gem.description   = ""
  gem.summary       = ""
  gem.homepage      = "http://github.com/bnorton/micro-q"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^spec/})
  gem.require_paths = ["lib"]

  gem.add_dependency             "celluloid"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "timecop"
  gem.add_development_dependency "psych"
  gem.add_development_dependency "activerecord", "> 3.2.0"
  gem.add_development_dependency "sqlite3-ruby"
end
