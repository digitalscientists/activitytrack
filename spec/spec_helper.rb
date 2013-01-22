require 'rspec'
require 'rack/test'

require File.expand_path('../../lib/activity_tracker.rb', __FILE__)

RSpec.configure do |config|
  config.mock_with :rspec
end
