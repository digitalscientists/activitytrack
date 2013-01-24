if defined? Rails
  require 'activity_tracker/version'
  require 'activity_tracker/configuration'
  require 'activity_tracker/app'
  require 'activity_tracker/interception'
  require 'activity_tracker/railtie'
else
  %w{version configuration app interception}.each do |mod|
    require File.expand_path(File.dirname(__FILE__) + "/activity_tracker/#{mod}")
   end
end

require 'rack'
require 'moneta'
require 'rack/moneta_store'
require 'net/http'
require 'json'


module ActivityTracker

  class << self
    def configuration
      @configuration ||= ActivityTracker::Configuration.new
    end
      
    def configure &block
      yield configuration
    end

  end

end
