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
        uri = ActivityTracker.configuration.uri
        @net ||= Net::HTTP.new(uri.host, uri.port)
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
      process_response EsRequest.net.request(http_request)
    end

    def http_request
      http_request = Net::HTTP::Post.new(path)
      http_request.body = body
      uri = ActivityTracker.configuration.uri
      unless uri.password.nil? || uri.user.nil?
        http_request.basic_auth uri.user, uri.password
      end
      http_request
    end


    def path
      "/#{ActivityTracker.configuration.index}" + if @type == :insert
        "/_bulk"
      elsif @type == :find
        "/#{@params[:act_type]}/_search"
      elsif @type == :update
        "/#{@params[:act_type]}/#{@params[:note_id]}/_update"
      end
    end

    def body
      if @type == :insert
        @params.map do |act|
          meta_data = {'_index' => ActivityTracker.configuration.index, '_type' => act['act_type']}
          params = act['params']
          unless params['_id'].nil?
            meta_data['_id'] = params['_id']
            params.delete('_id')
          end
          [
            {'index' => meta_data}.to_json,
            params.to_json
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
