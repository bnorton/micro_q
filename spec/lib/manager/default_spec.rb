require 'spec_helper'

describe MicroQ::Manager::Default do
  let(:create) { -> { subject } }

  describe '.new' do
    before do
      MicroQ.config.workers = 4
    end

    it 'should create a default queue' do
      MicroQ::Queue::Default.should_receive(:new_link)

      create.call
    end

    it 'should create a worker pool' do
      MicroQ::Worker::Standard.should_receive(:pool_link)

      create.call
    end

    it 'should be a config.workers size pool' do
      MicroQ::Worker::Standard.should_receive(:pool_link).with(hash_including(:size => 4))

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
        MicroQ::Queue::Default.stub(:new_link).and_return(@queue)

        @pool = mock(Celluloid::PoolManager, :idle_size => 1234, :perform! => nil)
        MicroQ::Worker::Standard.stub(:pool_link).and_return(@pool)
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

  describe '#reinitialize' do
    let(:death) { -> { subject.reinitialize } }

    before do
      @queue = mock(MicroQ::Queue::Default, :alive? => true, :dequeue => [])
      MicroQ::Queue::Default.stub(:new_link).and_return(@queue)

      @pool = mock(Celluloid::PoolManager, :alive? => true, :idle_size => 0)
      MicroQ::Worker::Standard.stub(:pool_link).and_return(@pool)

      subject.start
    end

    it 'should have the items' do
      subject.queue.should == @queue
      subject.workers.should == @pool
    end

    describe 'when the queue died' do
      before do
        @queue.stub(:alive?).and_return(false)

        @new_queue = mock(MicroQ::Queue::Default)
        MicroQ::Queue::Default.stub(:new_link).and_return(@new_queue)
      end

      it 'should restart the queue' do
        MicroQ::Queue::Default.should_receive(:new_link).and_return(@new_queue)

        death.call
      end

      it 'should have the new queue' do
        death.call

        subject.queue.should == @new_queue
      end
    end

    describe 'when the pool died' do
      before do
        @pool.stub(:alive?).and_return(false)

        @new_pool = mock(Celluloid::PoolManager)
        MicroQ::Worker::Standard.stub(:pool_link).and_return(@new_pool)
      end

      it 'should restart the pool' do
        MicroQ::Worker::Standard.should_receive(:pool_link).and_return(@new_pool)

        death.call
      end

      it 'should have the new pool' do
        death.call

        subject.workers.should == @new_pool
      end
    end
  end
end
