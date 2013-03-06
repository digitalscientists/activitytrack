module ActivityTracker
  class Configuration
    attr_accessor :batch_size, :index, :url

    def initialize
      @batch_size = 50
      @url = 'http://localhost:9200'
      @index = 'tracked_activities'
    end

    def uri
      URI.parse @url
    end

  end
end
