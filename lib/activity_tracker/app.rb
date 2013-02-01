module ActivityTracker
  class App

    def initialize app
      @app = app
    end

    def call env
      interception = Interception.new env
      if interception.intercept?
        interception.execute_update_que
        if interception.update?
          interception.complement_note
        else
          interception.track_activity
        end
        interception.response
      else
        @app.call env
      end
    rescue Exception => e
      puts e.inspect
    end

  end
end
