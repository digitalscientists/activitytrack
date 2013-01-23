if defined? Rails
  require 'activity_tracker/version'
  require 'activity_tracker/railtie'
else
  require File.expand_path(File.dirname(__FILE__) + '/activity_tracker/version')
end

require 'rack'
require 'moneta'
require 'rack/moneta_store'

#use Rack::MonetaStore, :Memory

module ActivityTracker
  class App

    def initialize app
      @app = app
    end

    def call env
      interception = Interception.new env
      if interception.intercept?
        interception.track_activity
        [200, {'Content-Type' => 'text/html'}, [interception.result.inspect]]
      else
        @app.call env
      end
    end

  end

  class Interception
    def initialize env
      @env = env
    end

    def request
      @request ||= Rack::Request.new @env
    end

    def valid_params?
      (request.params.keys & %w{user_id act}).size == 2
    end

    def valid_path?
      request.path_info =~ /^\/track_activity.*/
    end

    def intercept?
      valid_path? and valid_params?
    end

    def track_activity
      add_to_batch activity_params
      if batch_is_full?
        push_batch
        clear_batch
      end
    end

    def result
      batch
    end

  private

    def activity_params
      request.params.select { |k,v| %w{user_id act}.include? k.to_s }
    end

    def add_to_batch params
      store['activity_batch'] = batch << params
    end

    def push_batch

    end

    def clear_batch
      store['activity_batch'] = []
    end

    def batch_is_full?
      batch.size == 50 
    end

    def batch
      store.fetch('activity_batch', [])
    end

    def store
      @env['rack.moneta_store']
    end

  end

end
