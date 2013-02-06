module ActivityTracker
  class EsRequest

    attr_accessor :type, :params

    class << self

      [:insert, :find, :update].each do |request_type|
        define_method request_type do |params|
          request = new request_type, params
          request.execute
        end
      end

      def net
        @net ||= Net::HTTP.new('localhost',9200)
      end

      def log
        @requests ||= {:insert => [], :find => [], :update => []}
      end

      def reset_log
        @requests = {:insert => [], :find => [], :update => []}
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
      if @type == :insert
        "/tracked_activities/_bulk"
      elsif @type == :find
        "/tracked_activities/#{@params[:act_type]}/_search"
      elsif @type == :update
        "/tracked_activities/#{@params[:act_type]}/#{@params[:note_id]}/_update"
      end
    end

    def body
      if @type == :insert
        @params.map do |act|
          [
            {'index' => {'_index' => 'tracked_activities', '_type' => act['act_type'],}}.to_json,
            act['params'].to_json
          ].join("\n")
        end.flatten.join("\n") << "\n"
      elsif @type == :find
        { :query => { :term => @params[:query] } }.to_json
      elsif @type == :update
        { 
          :script => @params[:params].keys.map{ |key| "ctx._source.#{key} = #{key}" }.join('; '),
          :params => @params[:params] 
        }.to_json
      end
    end

    def process_response response
      EsRequest.log[type] << [path, params ,body, response.code, response.body]
      if response.code == '200'
        [200, JSON.parse(response.body)]
      else
        [400]
      end
    end
  end
end
