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
      @es_response = EsRequest.insert batch
    end

    def update_record
      if record_to_update_in_batch? request.params
        add_to_update_que request.params
      else
        resp = EsRequest.find :act_type => request.params['act_type'], :query => request.params['query']
        resp[1]['hits']['hits'].each do |hit|
          note_id = hit['_id']  
          @es_response = EsRequest.update :act_type => request.params['act_type'], :note_id => note_id, :params => request.params['params'].merge('user_id' => request.params['user_id'])
        end

      end
    end

    def record_to_update_in_batch? record_update
      batch.any? do |batch_record| 
        batch_record['act_type'] == record_update['act_type'] && batch_record['user_id'] == record_update['user_id'] && batch_record['params']['_id'] && record_update['query']['_id']
      end
    end

    def execute_update_que
      update_que.select { |update| !record_to_update_in_batch?(update) }.each do |update|
        EsRequset.update :act_type => params['act_type'], :note_id => note_id, :params => params['params'].merge(:user_id => params['user_id'])
      end
      store['update_que'] = update_que.select { |update| !record_to_update_in_batch?(update) }
    end

    def response
      unless es_response.nil?
        if insert?
          if es_response[0] == 200
            [200, {'Content-Type' => 'text/html'}, ['acivity stored']]
          else
            [400, {'Content-Type' => 'text/html'}, ['failed to insert data']]
          end
        elsif update?
          if es_response[0] == 200
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
      @es_response
    end

    def es_request_path
      if insert?
        "/tracked_activities/_bulk"
      elsif update?
        "/tracked_activities/#{request.params['act_type']}/#{request.params['user_id']}/_update"
      end
    end


  private

    def activity_params
      request.params.select { |k,v| %w{user_id act_type params}.include? k.to_s }
    end

    def add_to_batch params
      store['activity_batch'] = batch << params
    end

    def add_to_update_que params
      store['update_que'] = update_que << params
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

    def update_que
      store.fetch('update_que', [])
    end

    def store
      @env['rack.moneta_store']
    end

  end
end
