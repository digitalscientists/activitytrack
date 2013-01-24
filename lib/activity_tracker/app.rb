module ActivityTracker
  class App

    def initialize app
      @app = app
    end

    def call env
      interception = Interception.new env
      if interception.intercept?
        interception.track_activity
        interception.result
      else
        @app.call env
      end
    end

  end
end
