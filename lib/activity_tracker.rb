require "activity_tracker/version"

require 'activity_tracker/railtie' if defined? Rails

require 'rack'

module ActivityTracker
  class App
    def initialize app
      @app = app
    end

    def call env
#      raise Rack::Utils.parse_query(env['QUERY_STRING']).inspect
      if env['PATH_INFO'] =~ /^\/track_activity.*/ && valid_params?(env)
        [200, {'Content-Type' => 'text/html'}, ['tracking activity1!!']]   
      else
        @app.call env
      end
    end

  private
      
    def query env
      @query ||= Rack::Utils.parse_query(env['QUERY_STRING'])
    end

    def valid_params? env
      params = query(env)
      params.keys.include?('user_id') and params.keys.include?('action')
    end

  end
end
