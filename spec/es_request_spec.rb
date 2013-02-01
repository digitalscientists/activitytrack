require 'spec_helper'

module ActivityTracker
  describe EsRequest do
    let(:net){ mock :net_http_new }
    let(:request) {mock :es_request}
    before :each do
      EsRequest.stub(:net).and_return(net)
    end
    
    [:insert, :find, :update].each do |request_type|

      describe ".#{request_type}" do
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
    describe '#path'
    describe '#body'
    describe '#process_response'


  end
end
