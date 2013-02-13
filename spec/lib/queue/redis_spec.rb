require 'spec_helper'

describe MicroQ::Queue::Redis do
  let(:item) { { 'class' => 'MyWorker', 'args' => [4] } }

  describe '#sync_push' do
    it_behaves_like 'Queue#sync_push'

    describe 'when given the "when" key' do
      let(:worker) { [item, { 'when' => (Time.now + 100).to_i }] }

      it 'should add to the later' do
        subject.sync_push(*worker)

        subject.later.should include(item)
      end

      it 'should not be in the entries' do
        subject.sync_push(*worker)

        subject.entries.should == []
      end

      it 'should process the middleware chain' do
        MicroQ.middleware.client.should_receive(:call) do |w, payload, options|
          w.should == 'MyWorker'

          payload['class'].should == 'MyWorker'
          payload['args'].should == [4]
          options['when'].should == (Time.now + 100).to_i
        end

        subject.sync_push(*worker)
      end
    end

    describe 'when given the symbol :when key' do
      let(:worker) { [item, { :when => (Time.now + 100).to_i }] }

      it 'should add to the later' do
        subject.sync_push(*worker)

        subject.later.should include(item)
      end

      it 'should not be in the entries' do
        subject.sync_push(*worker)

        subject.entries.should == []
      end
    end
  end
end
