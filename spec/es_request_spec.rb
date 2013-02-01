require 'spec_helper'

module ActivityTracker
  describe EsRequest do
    let(:net){ mock :net_http_new }
    let(:request) {EsRequest.new :abstract_type, :abstract_params}
    before :each do
      EsRequest.stub(:net).and_return(net)
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
      before :each do
        @request = EsRequest.new :type, :params
        @request.stub(:path).and_return('path')
        @request.stub(:body).and_return('body')
        @request.stub(:process_response)
        Net::HTTP::Post.stub(:new).and_return(http_request)
        net.stub(:request).and_return('raw_es_response')
        http_request.stub(:body=)
      end
      it 'creates http request' do
        Net::HTTP::Post.should_receive(:new).with('path').and_return(http_request)
        @request.execute
      end

      it 'sets http request body' do
        http_request.should_receive(:body=).with('body')
        @request.execute
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
        request.path.should eq("/tracked_activities/any_action")
      end

      it 'when update request generates path for update request' do
        request.instance_variable_set('@type', :update)
        params[:act_type] = 'any_action'
        params[:note_id] = 'any_note'
        request.path.should eq('/tracked_activities/any_action/any_note/_update')
      end
    end
    describe '#body'
    describe '#process_response'


  end
end
