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
        MicroQ.middleware.client.should_receive(:call) do |payload, options|
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

  describe '#push' do
    before do
      @async = mock(Celluloid::ActorProxy)
      subject.stub(:async).and_return(@async)
    end

    it 'should asynchronously push the item' do
      @async.should_receive(:sync_push).with(*item)

      subject.push(*item)
    end
  end

  describe '#dequeue' do
    let(:item) { { 'class' => 'MyWorker', 'args' => [] } }

    class MyWorker
      def perform(*)
      end
    end

    describe 'when there are entries' do
      before do
        subject.sync_push(item)
      end

      it 'should return the item' do
        subject.dequeue.should == [item]
      end

      it 'should remove the item from the list' do
        subject.dequeue

        subject.entries.should_not include(item)
      end
    end

    describe 'when there are items to be processed later' do
      before do
        subject.sync_push(item, 'when' => (Time.now + 5).to_i)
      end

      it 'should not return the item' do
        subject.dequeue.should == []
      end

      it 'should not remove the item' do
        subject.dequeue

        subject.later.should == [item]
      end

      describe 'when the item is in the past' do
        let(:queue_name) { MicroQ::Queue::Redis::QUEUES[:later] }

        before do
          MicroQ.redis {|r| r.zadd(queue_name, (Time.now - 2).to_i, item.to_json) } # update its score
          subject.dequeue # move scheduled items to entries
        end

        it 'should return the item' do
          subject.dequeue.should == [item]
        end

        it 'should remove the item from the list' do
          subject.dequeue

          subject.later.should == []
        end
      end
    end

    describe 'when there are many items' do
      let(:later_item) { [item.dup.tap {|it| it['args'] = %w(special) }, 'when' => (Time.now + 5).to_i] }
      let(:items) do
        5.times.collect {|i|
          item.dup.tap {|it| it['args'] = [i]}
        }
      end

      before do
        items.first(4).each {|item| subject.sync_push(item) }
        subject.sync_push(items.last, 'when' => (Time.now - 2).to_i)

        subject.sync_push(*later_item)
      end

      it 'should return all the available items and move the schedule item' do
        subject.dequeue.sort {|x, y| x['args'][0] <=> y['args'][0] }.should == items.first(4)
        subject.entries.should include(items.last)

        subject.dequeue.should == items.last(1)
      end

      it 'should remove the items' do
        2.times { subject.dequeue }

        subject.entries.should == []
        subject.later.should == [later_item[0]]
      end

      describe 'when limited to a certain number' do
        it 'should return all the available items' do
          subject.dequeue(2).sort {|x, y| x['args'][0] <=> y['args'][0] }.should == items.first(2)
        end
      end
    end
  end
end
