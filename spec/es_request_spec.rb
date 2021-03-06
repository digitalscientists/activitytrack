require 'spec_helper'

module ActivityTracker
  describe EsRequest do
    let(:request) {EsRequest.new :abstract_type, :abstract_params}
    before :each do
      #EsRequest.stub(:net).and_return(net)
      ActivityTracker.configure do |config|
        config.index = 'tracked_activities'
      end
    end
    
    [:insert, :find, :update].each do |request_type|

      describe ".#{request_type}" do
      let(:request) {mock :es_request}
        after :each do
          EsRequest.send(request_type, :params)
        end
        it "creates #{request_type} request with params" do
          EsRequest.should_receive(:new).with(request_type, :params).and_return(request)
          request.stub(:execute)
        end
        it 'sends request' do
          EsRequest.stub(:new).and_return(request)
          request.should_receive(:execute)
        end
      end

    end
    describe '#new' do
      let(:request) { EsRequest.new :type, :params }
      it 'set type to @type' do
        request.instance_variable_get('@type').should eq(:type)
      end
      it 'set params to @params' do
        request.instance_variable_get('@params').should eq(:params)
      end
    end

    describe '#execute' do
      let(:http_request) {mock :http_request}
      let(:net){ mock :net_http_new }
      before :each do
        @request = EsRequest.new :type, :params
        @request.stub(:process_response)
        @request.stub(:http_request).and_return(http_request)
        EsRequest.stub(:net).and_return(net)
        net.stub(:request).and_return('raw_es_response')
      end

      it 'sends request' do
        net.should_receive(:request).with(http_request)
        @request.execute
      end

      it 'returns processed response' do
        @request.should_receive(:process_response).with('raw_es_response').and_return('response')
        @request.execute.should eq('response')
      end

    end
    describe '#path' do
      let(:params){ {} }
      before :each do
        request.instance_variable_set('@params', params)
      end
      
      it 'when insert request generates path for insert request' do
        request.instance_variable_set('@type', :insert)
        request.path.should eq('/tracked_activities/_bulk')
      end

      it 'when find request generates path for find request' do
        request.instance_variable_set('@type', :find)
        params[:act_type] = 'any_action'
        request.path.should eq("/tracked_activities/any_action/_search")
      end

      it 'when update request generates path for update request' do
        request.instance_variable_set('@type', :update)
        params[:act_type] = 'any_action'
        params[:note_id] = 'any_note'
        request.path.should eq('/tracked_activities/any_action/any_note/_update')
      end

      it "uses index name provided by configuration" do
        request.instance_variable_set('@type', :insert)
        ActivityTracker.configure do |config|
          config.index = 'custom_index'
        end
        request.path.should include('custom_index')
      end


    end
    describe '#body' do
      let(:params){ {} }
      context 'insert request' do
        before :each do
          request.type = :insert
        end
        it 'generates body forinsert request' do
          request.params = [
            {'act_type' => 'action_one', 'params' => {'param1' => 1, 'param2' => 2}},
            {'act_type' => 'action_two', 'params' => {'param1' => 3, 'param2' => 4}}
          ]

          request.body.should eq([
            '{"index":{"_index":"tracked_activities","_type":"action_one"}}',
            '{"param1":1,"param2":2}',
            '{"index":{"_index":"tracked_activities","_type":"action_two"}}',
            '{"param1":3,"param2":4}',
          ].join("\n") << "\n")
        end

        it 'moves "_id" parametr  from params to action meta_data' do
          request.params = [
            {'act_type' => 'action_one', 'params' => {'_id' => 1, 'param2' => 2}},
            {'act_type' => 'action_two', 'params' => {'_id' => 3, 'param2' => 4}}
          ]

          request.body.should eq([
            '{"index":{"_index":"tracked_activities","_type":"action_one","_id":1}}',
            '{"param2":2}',
            '{"index":{"_index":"tracked_activities","_type":"action_two","_id":3}}',
            '{"param2":4}',
          ].join("\n") << "\n")

        end

      end


      it 'when find request generate body for find request' do
        request.type = :find
        request.params = {:query => {'user_id' => 'u1d', 'item_id' => 'item_id'}}
        request.body.should eq('{"query":{"term":{"user_id":"u1d","item_id":"item_id"}}}')
      end
      it 'when update request generate body for update request' do
        request.type = :update
        request.params = {:params => {'new_attr1' => 'new value 1', 'new_attr2' => 'new value 2'}}
        request.body.should eq('{"script":"ctx._source.new_attr1 = new_attr1; ctx._source.new_attr2 = new_attr2","params":{"new_attr1":"new value 1","new_attr2":"new value 2"}}')
      end
      it 'uses index provided by configuration' do 
        ActivityTracker.configure do |config|
          config.index = 'custom_index'
        end
        request.type = :insert
        request.params = [
          {'act_type' => 'action_two', 'params' => {'param1' => 3, 'param2' => 4}}
        ]

        request.body.should include('custom_index')

      end
    end

    describe '#process_response' do
      let(:http_response) { mock(:http_response, :code => '200', :body => '{"key1": "value1"}') }

      before :each do
        request.stub(:type).and_return(:insert)
        request.stub(:path).and_return('/')
      end
      it 'returns array with  first element request status code' do
        http_response.stub(:code).and_return('400')
        request.process_response(http_response).first.should eq(400)
      end

      it 'when request is success returns array with second element request body in json' do
        request.process_response(http_response)[1].should eq({'key1' => 'value1'})
      end

      it 'adds data about current request to requests log'
    end

    describe '.net' do
      it 'requests to url specified in config' do
        ActivityTracker.configure do |config|
          config.url = 'http://user:password@somehost:8080'
        end
        Net::HTTP.should_receive(:new).with('somehost', 8080)
        EsRequest.instance_variable_set "@net", nil
        EsRequest.net
      end
    end

    describe '#http_request' do
      let(:http_request) { mock :http_request }
      before :each do
        request.stub(:path).and_return('/')
        request.stub(:body).and_return('body')
        http_request.stub(:body=)
        Net::HTTP::Post.stub(:new).and_return(http_request)
        ActivityTracker.configure do |config|
          config.url = 'http://somehost:8080'
        end
      end

      it 'creates http request' do 
        Net::HTTP::Post.should_receive(:new).with('/')
        request.http_request
      end

      it 'set request body' do
        http_request.should_receive(:body=).with('body')
        request.http_request
      end

      context 'url provided in config includes username and password' do
        before :each do
          ActivityTracker.configure do |config|
            config.url = 'http://user:password@somehost:8080'
          end
        end
        it 'set basic_auth' do
          http_request.should_receive(:basic_auth).with('user', 'password') 
          request.http_request
        end
      end
    end

  end
end
