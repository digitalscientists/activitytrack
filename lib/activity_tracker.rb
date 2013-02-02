%w{version configuration es_request interception insert_batch app}.each do |mod|
  if defined? Rails
    require File.expand_path(File.dirname(__FILE__) + "/activity_tracker/#{mod}")
  else
    require "activity_tracker/#{mod}"
  end
end
require 'activity_tracker/railtie' if defined? Rails

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
