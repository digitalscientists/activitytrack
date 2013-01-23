require 'spec_helper'

describe ActivityTracker::Interception do
  let(:interception) { ActivityTracker::Interception.new env}
  let(:env) { {} }
  let(:request) { mock :request, :params => {:user_id => 1, :act => 2, :other_param => 3} }
  describe '#track_activity' do
    
    before :each do
      interception.stub(:request).and_return(request)
      interception.stub(:batch_is_full?).and_return(false)
    end
    
    it 'adds action to batch' do
      interception.should_receive(:add_to_batch).with({:user_id => 1, :act => 2})
      interception.track_activity
    end

    context 'batch consist of less then 50 actions' do
      before :each do
        interception.stub(:add_to_batch)
        interception.stub(:batch_is_full?).and_return(true)
      end
      it 'pushes batch to elasticsearch' do
        interception.stub(:clear_batch)
        interception.should_receive(:push_batch)
        interception.track_activity
      end
      it 'clears batch' do
        interception.stub(:push_batch)
        interception.should_receive(:clear_batch)
        interception.track_activity
      end
    end

    context 'batch consist of 50 actions' do
      before :each do
        interception.stub(:add_to_batch)
        interception.stub(:batch_is_full?).and_return(false)
      end
      it 'does not push batch to elasticsearch' do
        interception.should_not_receive(:push_batch)
        interception.track_activity
      end
      it 'does not clear batch' do
        interception.should_not_receive(:clear_batch)
        interception.track_activity
      end
    end

  end
end
