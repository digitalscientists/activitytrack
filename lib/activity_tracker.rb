require "activity_tracker/version"

require 'activity_tracker/railtie' if defined? Rails

require 'rack'

module ActivityTracker
  class App
    def initialize app
      @app = app
    end

    def call env
      if env['PATH_INFO'] =~ /^\/track_activity.*/
        [200, {'Content-Type' => 'text/html'}, ['tracking activity1!!']]   
      else
        @app.call env
      end
    end
  end
end
