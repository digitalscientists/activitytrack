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

  describe 'when url does not include "/track_activity"' do

    it "does not intercept request" do
      get '/'
      last_response.body.should eq('not interesting')
    end

  end
  
  describe 'when url does include "/track_activity"' do

    it "does intercept request" do
      get '/track_activity'
      last_response.body.should eq('tracking activity1!!')
    end

  end

end
