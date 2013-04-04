module ActivityTracker
  class Interception
    attr_reader :batch, :update_que

    def initialize env
      @env = env
      @batch = InsertBatch.restore @env['rack.moneta_store']
      @update_que = UpdateQue.restore @env['rack.moneta_store']
      set_user_id_to_params
    end

    def request
      @request ||= Rack::Request.new @env
    end

    def set_user_id_to_params
      request.params['params']['user_id'] = request.cookies['at_uid'] if !request.cookies['at_uid'].nil? && !request.params['params'].nil?
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
      EsRequest.insert batch.data
    end

    def update_record
      update_que.add request.params
    end

    def find_records_for_update update
      resp = EsRequest.find(:act_type => update['act_type'], :query => update['query'])
      if resp[0] == 200
        resp[1]['hits']['hits']
      else 
        []
      end
    end

    def execute_update_que
      update_que.data.select { |update| !batch.includes_record?(update) }.each do |update|
        find_records_for_update(update).each do |record|
          EsRequest.update :act_type => update['act_type'], :note_id => record['_id'], :params => update['params']
        end
      end
      update_que.set update_que.data.select { |update| batch.includes_record?(update) }
    end

  private

    def store
      @env['rack.moneta_store']
    end

  end
end
