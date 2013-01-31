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
      interception.es_request_path.should eq('/tracked_activities/action_type/note_to_update_id/_update')
    end
  end
  


  describe '#update_record' do
    before :each do
      interception.stub(:data_prepared_for_update).and_return('update_data')
    end
    it "sends request to elasticsearch server" do
      interception.should_receive(:es_request).with('update_data')
      interception.update_record 
    end
    it "stores elasticsearch response" do
      interception.stub(:es_request).and_return('es response')
      interception.update_record
      interception.instance_variable_get('@raw_es_response').should eq('es response')
    end
  end
  describe '#es_request' do
    
    let(:request) { mock :request }

    before :each do
      @net = mock(:net)
      Net::HTTP.stub(:new).and_return(@net)
      @net.stub(:request)
      interception.stub(:insert?).and_return(true)
      interception.stub(:batch_prepared_for_push).and_return('')
      interception.stub(:es_request_path).and_return('')
    end
    it 'creates net object' do
      Net::HTTP.should_receive(:new)
      Net::HTTP::Post.stub(:new).and_return(request)
      request.stub(:body=)
      interception.es_request('')
    end

    it 'sends request' do
      Net::HTTP::Post.stub(:new).and_return(request)
      request.stub(:body=)
      @net.should_receive(:request).with(request)
      interception.es_request('')
    end

    it 'sets insert data to request body' do
      Net::HTTP::Post.stub(:new).and_return(request)
      request.should_receive(:body=).with('request data')
      interception.es_request('request data')
    end

    it 'creates post request' do
      request.stub(:body=)
      Net::HTTP::Post.should_receive(:new).and_return(request)
      interception.es_request('')
    end

  end
  describe '#data_prepared_for_update' do
    before :each do
      request.stub(:params).and_return({:key1 => 'key1', :key2 => 'key2'})
      @data = JSON.parse(interception.data_prepared_for_update)
    end
    it "creates es update script for each param key" do
      @data['script'].should match("ctx._source.key1 = key1; ctx._source.key2 = key2")
    end
    it "stores params to parametr named 'params'" do
      @data['params'].should eq({'key1' => 'key1', 'key2' => 'key2'})
    end
  end 
  describe '#response' do
    context 'when es response is present' do
      context 'when insert' do
        before :each do
          interception.stub(:insert?).and_return(true)
        end
        it 'returns "activity stored" 200 if es returns 200' do
          interception.stub(:es_response).and_return({:code => 200})
          interception.response.should eq([200, {'Content-Type' => 'text/html'}, ['acivity stored']])
        end

        it 'returns "failed to insert data" if es returns else than 200' do
          interception.stub(:es_response).and_return({:code => 400})
          interception.response.should eq([400, {'Content-Type' => 'text/html'}, ['failed to insert data']])
        end
      end
      context 'when update' do
        before :each do
          interception.stub(:insert?).and_return(false)
          interception.stub(:update?).and_return(true)
        end
        it 'returns "record updated" 200 if es returns 200' do
          interception.stub(:es_response).and_return({:code => 200})
          interception.response.should eq([200, {'Content-Type' => 'text/html'}, ['record updated']])
        end

        it 'returns "failed to update record" if es returns else than 200' do
          interception.stub(:es_response).and_return({:code => 400})
          interception.response.should eq([400, {'Content-Type' => 'text/html'}, ['failed to update record']])
        end

      end
    end
    context 'when es response is not present' do
      it 'returns "activity stored" 200' do
        interception.stub(:es_response).and_return(nil)
        interception.response.should eq([200, {'Content-Type' => 'text/html'}, ['acivity stored']])
      end
    end
  end

end
