module ActivityTracker
  class Interception
    attr_reader :batch

    def initialize env
      @env = env
      @batch = InsertBatch.restore @env['rack.moneta_store']
    end

    def request
      @request ||= Rack::Request.new @env
    end

    def insert?
      request.path_info =~ /^\/track_activity.*/ && (request.params.keys & %w{act_type params}).size == 2
    end

    def update?
      request.path_info =~ /^\/complement_note.*/ && (request.params.keys & %w{act_type params}).size == 2
    end

    def intercept?
      insert? or update?
    end

    def track_activity
      batch.add 'act_type' => request.params['act_type'], 'params' => request.params['params']
      if batch.full?
        push_batch
        batch.clear
      end
    end

    def complement_note
      update_record
    end

    def push_batch
      @es_response = EsRequest.insert @batch.data
    end

    def update_record
      if batch.includes_record? 'act_type' => request.params['act_type'], 'params' => request.params['query']
        add_to_update_que request.params
      else
        resp = EsRequest.find :act_type => request.params['act_type'], :query => request.params['query']
        resp[1]['hits']['hits'].each do |hit|
          note_id = hit['_id']  
          @es_response = EsRequest.update :act_type => request.params['act_type'], :note_id => note_id, :params => request.params['params']
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

  private

    def add_to_update_que params
      store['update_que'] = update_que << params
    end

    def update_que
      store.fetch('update_que', [])
    end

    def store
      @env['rack.moneta_store']
    end

  end
end
