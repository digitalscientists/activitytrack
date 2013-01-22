# -*- encoding: utf-8 -*-
require File.expand_path('../lib/activity_tracker/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Kmalyn"]
  gem.email         = ["kmalyn@softserveinc.com"]
  gem.description   = %q{Rack Middleware to track user activities}
  gem.summary       = %q{Rack Middleware to track user activities}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "activity_tracker"
  gem.require_paths = ["lib"]
  gem.version       = ActivityTracker::VERSION

  gem.add_runtime_dependency 'rack'

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rack-test'
  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'rb-fsevent', '~> 0.9.1'
end
