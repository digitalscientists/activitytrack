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

    describe 'there is no user_id sent' do
      it "does not intercept request" do
        get '/track_activity', :act_type => 1, :params => 3
        last_response.body.should eq('not interesting')
      end
    end

    describe 'there is no action sent' do
      it "does not intercept request" do
        get '/track_activity', :user_id => 1, :params => 3
        last_response.body.should eq('not interesting')
      end
    end

    describe 'there is no params sent' do
      it "does not intercept request" do
        get '/track_activity', :user_id => 1, :act_type => 2
        last_response.body.should eq('not interesting')
      end
    end

    describe 'user_id and action are sent' do
      it "does intercept request" do
        ActivityTracker::Interception.any_instance.should_receive(:track_activity)
        ActivityTracker::Interception.any_instance.stub(:response).and_return([200, {}, []])
        get '/track_activity', :user_id => 1, :act_type=> 2, :params => 3
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

    context 'there is no user_id sent' do
      it "does not intercept request" do
        get '/complement_note', :act_type => 1, :params => 3
        last_response.body.should eq('not interesting')
      end
    end

    context 'there is no action sent' do
      it "does not intercept request" do
        get '/complement_note', :user_id => 1, :params => 3
        last_response.body.should eq('not interesting')
      end
    end
      
    context 'there is no params sent' do
      it "does not intercept request" do
        get '/complement_note', :user_id => 1, :act_type => 2
        last_response.body.should eq('not interesting')
      end
    end

    describe 'user_id, action and params are sent' do
      it "does intercept request" do
        ActivityTracker::Interception.any_instance.should_receive(:complement_note)
        ActivityTracker::Interception.any_instance.stub(:response).and_return([200, {}, []])
        get '/complement_note', :user_id => 1, :act_type=> 2, :params => 3
      end
    end

  end


end
