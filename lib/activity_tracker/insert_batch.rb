module ActivityTracker
  class InsertBatch
    class << self
      def restore storage
        @storage = storage
        @key = 'activity_insert_batch'
        self
      end

      def add record
        storage[@key] = data << record
      end

      def full?
        data.size >= ActivityTracker.configuration.batch_size
      end

      def includes_record? query
        data.select { |r| r['act_type'] == query['act_type'] }.
          map{ |r| r['params'] }.
          select do |r| 
            ((query['params'].keys & r.keys).size == query['params'].keys.size) && query['params'].keys.inject(true){ |result, key| query['params'][key] == r[key] }
          end.any?

      end

      def data
        storage.fetch(@key, [])
      end

      def storage
        @storage
      end

    end
  end
end
