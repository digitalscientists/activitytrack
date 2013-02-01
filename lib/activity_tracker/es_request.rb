module ActivityTracker
  class EsRequest

    class << self

      [:insert, :find, :update].each do |request_type|
        define_method request_type do |params|
          request = new request_type, params
          request.execute
        end
      end

    end

    def initialize type, params
      @type = type
      @params = params
    end

    def execute
      http_request = Net::HTTP::Post.new(path)
      http_request.body = body
      process_response EsRequest.net.request(http_request)
    end

    def path
      if @pamms
        "/tracked_activities/_bulk"
      elsif update?
        "/tracked_activities/#{request.params['act_type']}/#{request.params['user_id']}/_update"
      end
    end

  end
end
