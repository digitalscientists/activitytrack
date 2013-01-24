
module ActivityTracker
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
      if @result
        ok = @result.body =~ /\"ok\":true/
         [( ok ? 200 : 400), {'Content-Type' => 'text/html'}, [ok ? 'acivity stored' : 'failed to store activity']]
      else
         [200, {'Content-Type' => 'text/html'}, ['acivity stored']]
      end
    end

  private

    def activity_params
      request.params.select { |k,v| %w{user_id act}.include? k.to_s }
    end

    def add_to_batch params
      store['activity_batch'] = batch << params
    end

    def push_batch
      net = Net::HTTP.new('localhost',9200)
      es_request = Net::HTTP::Post.new('tracking/activity/_bulk')
      es_request.body = batch_prepared_for_store
      @result = net.request es_request
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
  
    def batch_prepared_for_store
      batch.map do |act|
        [
          {'index' => {'_index' => 'tracking', '_type' => 'activity',}}.to_json,
          act.to_json
        ]
      end.flatten.join("\n")
    end

  end
end
