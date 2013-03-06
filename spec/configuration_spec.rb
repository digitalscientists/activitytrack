require 'spec_helper'

describe ActivityTracker do

  it 'has configuration' do
    ActivityTracker.configuration.should be_an_instance_of(ActivityTracker::Configuration)
  end

  it 'can be configured' do
    ActivityTracker.configure do |config|
      config.batch_size = 100
    end

    config = ActivityTracker.configuration
    config.batch_size.should eq(100)
  end

  describe '#uri' do
    it 'parses provided url provided to it' do
      ActivityTracker.configure do |config|
        config.url = 'http://user:password@somehost:8080'
      end
      URI.should_receive(:parse).with('http://user:password@somehost:8080')
      ActivityTracker.configuration.uri
    end
  end


end
