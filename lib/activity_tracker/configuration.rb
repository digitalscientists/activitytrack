module ActivityTracker
  class Configuration
    attr_accessor :batch_size

    def initialize
      @batch_size = 50
    end

  end
end
