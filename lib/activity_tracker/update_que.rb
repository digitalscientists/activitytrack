module ActivityTracker
  class UpdateQue
    class << self
      def restore storage
        @storage = storage
        @key = 'activity_update_que'
        self
      end

      def add record
        storage[@key] = data << record
      end

      def data
        storage.fetch(@key, [])
      end

      def storage
        @storage
      end

      def set records
        storage[@key] = records
      end
    end
  end
end
