require 'spec_helper'

describe ActivityTracker::Interception do
  let(:interception) { ActivityTracker::Interception.new env}
  let(:env) { {} }
  let(:request) { mock :request, :path_info => 'huy', :params => {:user_id => 1, :act_type => 2, :other_param => 3} }


    before :each do
      interception.stub(:request).and_return(request)
    end

  describe '#track_activity' do
  
    before :each do
      interception.stub(:batch_is_full?).and_return(false)
    end
    
    it 'adds action to batch' do
      interception.should_receive(:add_to_batch).with({:user_id => 1, :act_type => 2})
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

  describe '#valid_path?' do

    it 'returns true when path starts from "/track_activity"' do
      request.stub!(:path_info).and_return('/track_activity1')
      interception.valid_path?.should be_true
    end
    it 'returns true when path starts from "/complement_note"' do
      request.stub!(:path_info).and_return('/complement_note')
      interception.valid_path?.should be_true
    end
    it 'returns false when path starts from any other string' do
      request.stub!(:path_info).and_return('/some_path')
      interception.valid_path?.should_not be_true
    end

  end

  describe '#intercept?' do
    before :each do
      interception.stub(:insert?).and_return(false)
      interception.stub(:update?).and_return(false)
    end
    it 'returns true if request is recognized as insert' do
      interception.stub(:insert?).and_return(true)
      interception.intercept?.should be_true
    end
    it 'returns true if request is recognized as update' do
      interception.stub(:update?).and_return(true)
      interception.intercept?.should be_true
    end
    it 'returns false if request is not recognized as insert or update' do
      interception.intercept?.should_not be_true
    end
  end

  describe '#insert?' do
    context 'params are valid' do
      before :each do
        request.stub(:params).and_return({'user_id' => 1, 'act_type' => 2, 'params' => 3})
      end
      it 'returns true if request is update when path is "/track_activity"' do
        request.stub!(:path_info).and_return('/track_activity')
        interception.insert?.should be_true
      end
      it 'returns false if request is update when path is not "/track_activity"' do
        request.stub!(:path_info).and_return('/not_track_activity')
        interception.insert?.should_not be_true
      end
    end
    context 'request path is valid' do
      before :each do
        request.stub!(:path_info).and_return('/track_activity')
      end
      it 'returns true if params includes "user_id", "act_type" and "params" parametrs' do
        request.stub(:params).and_return({'user_id' => 1, 'act_type' => 2, 'params' => 3})
        interception.insert?.should be_true
      end
      it 'returns false if request does not include "user_id" parametr' do
        request.stub(:params).and_return({'act_type' => 2, 'params' => 3})
        interception.insert?.should_not be_true
      end
      it 'returns false if request does not include "act_type" parametr' do
        request.stub(:params).and_return({'user_id' => 1, 'params' => 3})
        interception.insert?.should_not be_true
      end
      it 'returns false if request does not include "params" parametr' do
        request.stub(:params).and_return({'user_id' => 1, 'act_type' => 2})
        interception.insert?.should_not be_true
      end
    end
  end


  describe '#update?' do
    context 'params are valid' do
      before :each do
        request.stub(:params).and_return({'note_id' => 1, 'act_type' => 2, 'params' => 3})
      end
      it 'returns true if request is update when path is "/complement_note"' do
        request.stub!(:path_info).and_return('/complement_note')
        interception.update?.should be_true
      end
      it 'returns false if request is update when path is not "/track_activity"' do
        request.stub!(:path_info).and_return('/not_complement_note')
        interception.update?.should_not be_true
      end
    end
    context 'request path is valid' do
      before :each do
        request.stub!(:path_info).and_return('/complement_note')
      end
      it 'returns true if params includes "note_id", "act_type" and "params" parametrs' do
        request.stub(:params).and_return({'note_id' => 1, 'act_type' => 2, 'params' => 3})
        interception.update?.should be_true
      end
      it 'returns false if request does not include "user_id" parametr' do
        request.stub(:params).and_return({'act_type' => 2, 'params' => 3})
        interception.update?.should_not be_true
      end
      it 'returns false if request does not include "act_type" parametr' do
        request.stub(:params).and_return({'note_id' => 1, 'params' => 3})
        interception.update?.should_not be_true
      end
      it 'returns false if request does not include "params" parametr' do
        request.stub(:params).and_return({'note_id' => 1, 'act_type' => 2})
        interception.update?.should_not be_true
      end
    end
  end

  describe '#es_request_path' do
    it 'generates path for bulk insert' do
      interception.stub(:insert?).and_return(true)
      interception.es_request_path.should eq('/tracked_activities/_bulk')
    end
    it 'generates path for record update' do
      request.stub(:params).and_return({'act_type' => 'action_type', 'note_id' => 'note_to_update_id'})
      interception.stub(:insert?).and_return(false)
      interception.stub(:update?).and_return(true)
      interception.es_request_path.should eq('/tracked_activities/action_type/note_to_update_id')
    end
  end

end
