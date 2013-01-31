module ActivityTracker
  class Interception

    def initialize env
      @env = env
    end

    def request
      @request ||= Rack::Request.new @env
    end

    def insert?
      request.path_info =~ /^\/track_activity.*/ && (request.params.keys & %w{user_id act_type params}).size == 3
    end

    def update?
      request.path_info =~ /^\/complement_note.*/ && (request.params.keys & %w{user_id act_type params}).size == 3
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

    def push_batch
      @raw_es_response = es_request(batch_prepared_for_push)
    end

    def update_record
      @raw_es_response = es_request(data_prepared_for_update)
    end

    def response
      unless es_response.nil?
        if insert?
          if es_response[:code] == 200
            [200, {'Content-Type' => 'text/html'}, ['acivity stored']]
          else
            [400, {'Content-Type' => 'text/html'}, ['failed to insert data']]
          end
        elsif update?
          if es_response[:code] == 200
            [200, {'Content-Type' => 'text/html'}, ['record updated']]
          else
            [400, {'Content-Type' => 'text/html'}, ['failed to update record']]
          end
        end
      else
         [200, {'Content-Type' => 'text/html'}, ['acivity stored']]
      end
    end

    def es_response
      if @raw_es_response.present?
        @es_response ||= { 
          :body => JSON.parse(@raw_es_response.body),
          :code => @raw_es_response.code
        }
      end
    end

    def es_request_path
      if insert?
        "/tracked_activities/_bulk"
      elsif update?
        "/tracked_activities/#{request.params['act_type']}/#{request.params['user_id']}/_update"
      end
    end

    def es_request data
      net = Net::HTTP.new('localhost',9200)
      es_request = Net::HTTP::Post.new(es_request_path)
      es_request.body = data
      net.request es_request
    end

    def data_prepared_for_update
      {
        :script => request.params.keys.map { |key| "ctx._source.#{key} = #{key}" }.join('; '),
        :params => request.params
      }.to_json
    end


  private

    def activity_params
      request.params.select { |k,v| %w{user_id act_type params}.include? k.to_s }
    end

    def add_to_batch params
      store['activity_batch'] = batch << params
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
          {'index' => {'_index' => 'tracked_activities', '_type' => act['act_type'],}}.to_json,
          act.to_json
        ]
      end.flatten.join("\n")
    end

  end
end
