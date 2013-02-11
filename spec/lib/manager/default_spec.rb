require 'spec_helper'

describe MicroQ::Manager::Default do
  let(:create) { -> { subject } }

  describe '.new' do
    before do
      MicroQ.config.workers = 4
    end

    it 'should create a default queue' do
      MicroQ::Queue::Default.should_receive(:new)

      create.call
    end

    it 'should create a worker pool' do
      MicroQ::Worker::Standard.should_receive(:pool)

      create.call
    end

    it 'should be a config.workers size pool' do
      MicroQ::Worker::Standard.should_receive(:pool).with(hash_including(:size => 4))

      create.call
    end
  end

  describe '#queue' do
    it 'should be the queue' do
      subject.queue.wrapped_object.class.should == MicroQ::Queue::Default
    end
  end

  describe '#workers' do
    it 'should be the workers' do
      subject.workers.class.should == Celluloid::PoolManager
      subject.workers.inspect.should match(/MicroQ::Worker::Standard/)
    end
  end

  describe '#start' do
    it 'should not be performing' do
      subject.workers.should_not_receive(:perform!)

      subject.start
    end

    describe 'when the queue has dequeue-able items' do
      before do
        @item, @other_item = mock(Hash), mock(Hash)
        @queue = mock(MicroQ::Queue::Default, :dequeue => [@item, @other_item])
        MicroQ::Queue::Default.stub(:new).and_return(@queue)

        @pool = mock(Celluloid::PoolManager, :idle_size => 1234, :perform! => nil)
        MicroQ::Worker::Standard.stub(:pool).and_return(@pool)
      end

      it 'should dequeue the number of free workers' do
        @queue.should_receive(:dequeue).with(1234)

        subject.start
      end

      it 'should perform the items' do
        @pool.should_receive(:perform!).with(@item) do
          @pool.should_receive(:perform!).with(@other_item)
        end

        subject.start
      end
    end
  end
end
