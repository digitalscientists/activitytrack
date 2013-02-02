require 'spec_helper'

describe ActivityTracker::Interception do
  let(:interception) { ActivityTracker::Interception.new env}
  let(:env) { {} }
  let(:request) { mock :request, :path_info => 'path', :params => {'act_type' => 1, 'params' => 2, 'other_param' => 3} }


    before :each do
      interception.stub(:request).and_return(request)
    end

  describe '#track_activity' do
    let(:batch) { mock :batch }
  
    before :each do
      interception.stub(:batch).and_return(batch)
      batch.stub(:full?).and_return(false)
    end
    
    it 'adds action to batch' do
      batch.should_receive(:add).with({'act_type' => 1, 'params' => 2})
      interception.track_activity
    end

    context 'batch consist of less then 50 actions' do
      before :each do
        batch.stub(:add)
        batch.stub(:full?).and_return(true)
      end
      it 'pushes batch to elasticsearch' do
        batch.stub(:clear)
        interception.should_receive(:push_batch)
        interception.track_activity
      end
      it 'clears batch' do
        interception.stub(:push_batch)
        batch.should_receive(:clear)
        interception.track_activity
      end
    end

    context 'batch consist of 50 actions' do
      before :each do
        batch.stub(:add)
        batch.stub(:full?).and_return(false)
      end
      it 'does not push batch to elasticsearch' do
        interception.should_not_receive(:push_batch)
        interception.track_activity
      end
      it 'does not clear batch' do
        batch.should_not_receive(:clear)
        interception.track_activity
      end
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
        request.stub(:params).and_return({'act_type' => 2, 'params' => 3})
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
      it 'returns true if params includes "act_type" and "params" parametrs' do
        request.stub(:params).and_return({'act_type' => 2, 'params' => 3})
        interception.insert?.should be_true
      end
      it 'returns false if request does not include "act_type" parametr' do
        request.stub(:params).and_return({'params' => 3})
        interception.insert?.should_not be_true
      end
      it 'returns false if request does not include "params" parametr' do
        request.stub(:params).and_return({'act_type' => 2})
        interception.insert?.should_not be_true
      end
    end
  end


  describe '#update?' do
    context 'params are valid' do
      before :each do
        request.stub(:params).and_return({'act_type' => 2, 'params' => 3})
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
      it 'returns true if params includes "act_type" and "params" parametrs' do
        request.stub(:params).and_return({'act_type' => 2, 'params' => 3})
        interception.update?.should be_true
      end
      it 'returns false if request does not include "act_type" parametr' do
        request.stub(:params).and_return({'params' => 3})
        interception.update?.should_not be_true
      end
      it 'returns false if request does not include "params" parametr' do
        request.stub(:params).and_return({'act_type' => 2})
        interception.update?.should_not be_true
      end
    end
  end

  


  describe '#update_record' do
    let(:update_params) do
      {
        'act_type' => 'abs_act',
        'params' => {'key1' => 'value 1'},
        'query' => 'abs_query'
      }
    end
    
    let(:update_que){mock :update_que}

    before :each do
      interception.stub(:data_prepared_for_update).and_return('update_data')
      interception.stub(:update_que).and_return(update_que)
      request.stub(:params).and_return(update_params)
    end
    it 'pushes update to update que' do
      update_que.should_receive(:add).with(update_params)
      interception.update_record
    end
=begin
    context 'record to update found in batch' do

      before :each do 
        interception.stub(:record_to_update_in_batch?).and_return true
      end

      it 'pushes update to update que' do
        interception.should_receive(:add_to_update_que).with(update_params)
        interception.update_record
      end
    end

    context 'record to update not found in batch' do
      let(:es_response) {[200, {'hits' => {'hits' => [{'_id' => '11' }]}}]}
      before :each do 
        interception.stub(:record_to_update_in_batch?).and_return false
      end
      it 'searches for record in ES' do
        ActivityTracker::EsRequest.stub(:update)
        ActivityTracker::EsRequest.should_receive(:find).with({
          :act_type => 'abs_act',
          :query => 'abs_query'
        }).and_return(es_response)
        interception.update_record
      end
      it 'when found in es updates record' do
        ActivityTracker::EsRequest.stub(:find).and_return(es_response)
        ActivityTracker::EsRequest.should_receive(:update).with({
          :act_type => 'abs_act',
          :note_id => '11',
          :params => {'key1' => 'value 1'}
        })
        interception.update_record
      end
      it 'when not found in es updates record'
    end
=end

  end



end
