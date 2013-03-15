require 'spec_helper'

describe MicroQ::Queue::Default do
  let(:item) { { 'class' => 'MyWorker', 'args' => [4] } }

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
    it_behaves_like 'Queue#sync_push'

    describe 'when given the \'when\' key' do
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

      describe 'when limited to a certain number' do
        it 'should return all the available items' do
          subject.dequeue(2).sort {|x, y| x['args'][0] <=> y['args'][0] }.should == items.first(2)
        end
      end
    end
  end

  describe '#stop' do
    let(:file_name) { '/some/file/queue.yml' }

    describe 'when there are items in the queue' do
      let(:other_item) { { 'class' => 'MyWorker', 'args' => ['hello'] } }

      before do
        MicroQ.configure {|c| c.queue_file = file_name }

        @file = mock(File, :write => nil)
        File.stub(:open).with(file_name, 'w+').and_yield(@file)
        File.stub(:exists?).and_return(false)
        File.stub(:exists?).with(File.dirname(file_name)).and_return(true)

        subject.push(item)
        subject.push(other_item)
      end

      it 'should create the target file' do
        File.should_receive(:open).with(file_name, 'w+')

        subject.stop
      end

      it 'should write the entries' do
        @file.should_receive(:write).with(YAML.dump([item, other_item]))

        subject.stop
      end

      describe 'when the file directory does not exist' do
        before do
          File.stub(:exists?).with(File.dirname(file_name)).and_return(false)
        end

        it 'should not write the file' do
          File.should_not_receive(:open)

          subject.stop
        end
      end
    end
  end

  describe '.new' do
    let!(:file_name) { '/some/other/file/queue.yml' }
    let(:queue) { -> { subject } }

    before do
      MicroQ.configure {|c| c.queue_file = file_name }
    end

    describe 'when there are persisted queue items' do
      before do
        File.stub(:exists?).with(File.dirname(file_name)).and_return(true)
        File.stub(:exists?).with(file_name).and_return(true)
        File.stub_chain(:new, :read).and_return(YAML.dump([item]))

        File.stub(:unlink)
      end

      it 'should check the file existence' do
        File.should_receive(:exists?).with(File.dirname(file_name)).and_return(true)
        File.should_receive(:exists?).with(file_name).and_return(false)

        queue.call
      end

      it 'should open the file' do
        File.should_receive(:new).with(file_name)

        queue.call
      end

      it 'should remove the file' do
        File.should_receive(:unlink).with(file_name)

        queue.call
      end

      it 'should read the file to place the items in the queue' do
        queue.call

        subject.entries.should == [item]
      end
    end
  end
end
