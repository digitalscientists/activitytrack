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
    #def self.call env
    #  new self
    #end

    def initialize app
      @app = app
    end

    def call env
      interception = Interception.new env
      if interception.intercept?
        [200, {'Content-Type' => 'text/html'}, ['tracking activity1!!']]
        store_action env
      else
        @app.call env
      end
    end

    def store_action env
      store(env)['activity_cache'] = store(env).fetch('activity_cache', []) << 1

      [200, {'Content-Type' => 'text/html'}, [store(env)['activity_cache'].inspect]]
      #Net::Http.new('http://localhost:9200').post query(env)
    end

  private

    def store env
      env['rack.moneta_store']
    end
      
    def query env
      @query ||= Rack::Utils.parse_query(env['QUERY_STRING'])
    end

    def valid_params? env
      params = query(env)
      params.keys.include?('user_id') and params.keys.include?('act')
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
  end

end
