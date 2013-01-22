require 'rack'
require 'rack/lobster'
#puts FileUtils.pwd
#require "#{FileUtils.pwd}/lib/activity_tracker"


use ActivityTracker::App
run Rack::Lobster.new
#run ActivityTracker.new

