require 'spec_helper'

module ActivityTracker
  describe InsertBatch do

    describe '#includes_record?' do
      let(:data) do
        [
          {'act_type' => 'add', 'params' => {'title' => 'Oggy', 'item_id' => '10'}},
          {'act_type' => 'add', 'params' => {'title' => 'Funny', 'item_id' => '2'}},
          {'act_type' => 'open', 'params' => {'title' => 'Crazy', 'item_id' => '11'}},
          {'act_type' => 'open', 'params' => {'title' => 'Lucky', 'item_id' => '8'}},
        ]
      end

      before :each do
        InsertBatch.stub(:data).and_return(data)
      end

      it 'when record found returns true' do
        InsertBatch.includes_record?('act_type' => 'add', 'params' => {'item_id' => '10'}).should be_true
      end
      it 'when record not found returns false' do
        InsertBatch.includes_record?('act_type' => 'add', 'params' => {'item_id' => '11'}).should_not be_true
      end
    end

  end
end
