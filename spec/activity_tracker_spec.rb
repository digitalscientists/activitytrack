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

  describe 'url does not include "/track_activity"' do

    it "does not intercept request" do
      get '/'
      last_response.body.should eq('not interesting')
    end

  end
  
  describe 'url does include "/track_activity"' do

    describe 'no params sent' do
      it "does not intercept request" do
        get '/track_activity'
        last_response.body.should eq('not interesting')
      end
    end

    describe 'there is no user_id sent' do
      it "does not intercept request" do
        get '/track_activity', :action => 1
        last_response.body.should eq('not interesting')
      end
    end

    describe 'there is no action sent' do
      it "does not intercept request" do
        get '/track_activity', :user_id => 1
        last_response.body.should eq('not interesting')
      end
    end

    describe 'user_id and action are sent' do
      it "does not intercept request" do
        get '/track_activity', :user_id => 1, :action => 1
        last_response.body.should eq('tracking activity1!!')
      end
    end

  end

end
