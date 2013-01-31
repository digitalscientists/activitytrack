
module ActivityTracker
  class Interception

    def initialize env
      @env = env
    end

    def request
      @request ||= Rack::Request.new @env
    end

    def valid_params?
      (request.params.keys & %w{user_id act_type}).size == 2
    end

    def valid_path?
      request.path_info =~ /^\/(track_activity|complement_note).*/
    end

    def insert?
      request.path_info =~ /^\/track_activity.*/ && (request.params.keys & %w{user_id act_type params}).size == 3
    end

    def update?
      request.path_info =~ /^\/complement_note.*/ && (request.params.keys & %w{note_id act_type params}).size == 3
    end

    def intercept?
      insert? or update?
    end

    def track_activity
      add_to_batch activity_params
      if batch_is_full?
        push_batch
        clear_batch
      end
    end

    def complement_note
      update_record
    end

    def update_record
      @raw_es_response = es_request(data_prepared_for_update)
    end

    def result
      if @result
        ok = @result.body =~ /\"ok\":true/
         [( ok ? 200 : 400), {'Content-Type' => 'text/html'}, [ok ? 'acivity stored' : 'failed to store activity']]
      else
         [200, {'Content-Type' => 'text/html'}, ['acivity stored']]
      end
    end

    def es_request_path
      if insert?
        "/tracked_activities/_bulk"
      elsif update?
        "/tracked_activities/#{request.params['act_type']}/#{request.params['note_id']}"
      end
    end

    def es_request data
      net = Net::HTTP.new('localhost',9200)
      if insert?
        es_request = Net::HTTP::Post.new(es_request_path)
      elsif update?
        es_request = Net::HTTP::Put.new(es_request_path)
      end
      es_request.body = data
      net.request es_request
    end


  private

    def activity_params
      request.params.select { |k,v| %w{user_id act_type}.include? k.to_s }
    end

    def add_to_batch params
      store['activity_batch'] = batch << params
    end

    def push_batch
      net = Net::HTTP.new('localhost',9200)
      es_request = Net::HTTP::Post.new('tracking/activity/_bulk')
      es_request.body = batch_prepared_for_push
      @result = net.request es_request
    end

    def clear_batch
      store['activity_batch'] = []
    end

    def batch_is_full?
      batch.size == ActivityTracker.configuration.batch_size
    end

    def batch
      store.fetch('activity_batch', [])
    end

    def store
      @env['rack.moneta_store']
    end
  
    def batch_prepared_for_push
      batch.map do |act|
        [
          {'index' => {'_index' => 'tracking', '_type' => 'activity',}}.to_json,
          act.to_json
        ]
      end.flatten.join("\n")
    end

  end
end
