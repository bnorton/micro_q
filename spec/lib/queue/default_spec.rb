require 'spec_helper'

describe MicroQ::Queue::Default do
  describe '#entries' do
    it 'should be empty' do
      subject.entries.should == []
    end
  end

  describe '#later' do
    it 'should be empty' do
      subject.later.should == []
    end
  end

  describe '#sync_push' do
    let(:item) { { 'class' => 'MyWorker', 'args' => [4] } }

    it 'should add to the entries' do
      subject.sync_push(item)

      subject.entries.should include(item)
    end

    it 'should duplicate the item' do
      subject.sync_push(item)

      before = item.dup
      subject.entries.should include(before)

      item[:key] = 'new-value'
      subject.entries.should_not include(item)
      subject.entries.should include(before)
    end

    describe 'client middleware' do
      it 'should process the middleware chain' do
        MicroQ.middleware.client.should_receive(:call) do |w, payload|
          w.should == 'MyWorker'

          payload['class'].should == 'MyWorker'
          payload['args'].should == [4]
        end

        subject.sync_push(item)
      end
    end

    describe 'when given the "when" key' do
      let(:worker) { [item, { 'when' => (Time.now + 100).to_i }] }

      it 'should add to the later' do
        subject.sync_push(*worker)

        subject.later.should include(
          'when' => (Time.now + 100).to_i,
          'worker' => item
        )
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

        subject.later.should include(
          'when' => (Time.now + 100).to_i,
          'worker' => item
        )
      end

      it 'should not be in the entries' do
        subject.sync_push(*worker)

        subject.entries.should == []
      end
    end
  end

  describe '#push' do
    let(:item) { { 'class' => 'MyWorker', 'args' => [4] } }

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

        subject.later.should == ['when' => (Time.now + 5).to_i, 'worker' => item]
      end

      describe 'when the item is in the past' do
        before do
          subject.later.first['when'] = (Time.now - 2).to_i
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

      it 'should return all the available items' do
        subject.dequeue.sort {|x, y| x['args'][0] <=> y['args'][0] }.should == items
      end

      it 'should remove the items' do
        subject.dequeue

        subject.entries.should == []
        subject.later.should == [later_item[1].merge('worker' => later_item[0])]
      end
    end
  end
end
