require 'spec_helper'

def create_app status, headers, content
  app = lambda { |env| [status, headers, [content]] }
  ActivityTracker::App.new app
end

describe ActivityTracker::App do
  include Rack::Test::Methods

  let(:app) { create_app(status, headers, content) }
  let(:status) { 200 }
  let(:headers) { {'Content-Type' => 'text/html'} }
  let(:content) {'not interesting'}

  context 'url does not include "/track_activity"' do

    it "does not intercept request" do
      get '/'
      last_response.body.should eq('not interesting')
    end

  end
  
  context 'url does include "/track_activity"' do

    describe 'no params sent' do
      it "does not intercept request" do
        get '/track_activity'
        last_response.body.should eq('not interesting')
      end
    end

    describe 'there is no action sent' do
      it "does not intercept request" do
        get '/track_activity', :params => 3
        last_response.body.should eq('not interesting')
      end
    end

    describe 'there is no params sent' do
      it "does not intercept request" do
        get '/track_activity', :act_type => 2
        last_response.body.should eq('not interesting')
      end
    end

    describe 'params and action are sent' do
      it "does intercept request" do
        ActivityTracker::Interception.any_instance.should_receive(:execute_update_que)
        ActivityTracker::Interception.any_instance.should_receive(:track_activity)
        ActivityTracker::App.any_instance.stub(:response).and_return('')
        get '/track_activity', :act_type=> 2, :params => 3
      end
    end

  end

  describe 'url does include "/complement_note"' do
    context 'no params sent' do
      it "does not intercept request" do
        get '/complement_note'
        last_response.body.should eq('not interesting')
      end
    end

    context 'there is no action sent' do
      it "does not intercept request" do
        get '/complement_note', :params => 3
        last_response.body.should eq('not interesting')
      end
    end
      
    context 'there is no params sent' do
      it "does not intercept request" do
        get '/complement_note', :act_type => 2
        last_response.body.should eq('not interesting')
      end
    end

    describe 'user_id, action and params are sent' do
      it "does intercept request" do
        ActivityTracker::Interception.any_instance.should_receive(:execute_update_que)
        ActivityTracker::Interception.any_instance.should_receive(:complement_note)
        #app.stub(:response)#.and_return([200, {}, []])
        #ActivityTracker::Interception.any_instance.stub(:response).and_return([200, {}, []])
        ActivityTracker::App.any_instance.stub(:response).and_return('')
        get '/complement_note', :act_type=> 2, :params => 3
      end
    end

  end


end
