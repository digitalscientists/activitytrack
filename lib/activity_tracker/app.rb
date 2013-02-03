module ActivityTracker
  class App

    def initialize app
      @app = app
    end

    def call env
      interception = Interception.new env
      if interception.intercept?
        if interception.update?
          interception.complement_note
        else
          interception.track_activity
        end
        interception.execute_update_que
        [200, {'Content-Type' => 'text/html'}, [response]]
      else
        @app.call env
      end
    end

    def response
      string = ''
      EsRequest.log.each_pair do |type, requests|
        if requests.any?
          string += "<h1>#{type} requests:</h2>"
          string += requests.map do |request|
            "<ul><li>#{request.join('</li><li>')}</li></ul>"
          end.join('<hr>')  
        end
      end
      EsRequest.reset_log
      string
    end

  end
end
