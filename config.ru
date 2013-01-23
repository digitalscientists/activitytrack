require 'rack'
require 'rack/lobster'
require File.expand_path(File.dirname(__FILE__) + '/lib/activity_tracker')

use Rack::MonetaStore, :Memory
use ActivityTracker::App
run Proc.new {|env| [200, {'Content-Type' => 'text/html'}, ['Hello World!']]}
#run ActivityTracker.new

