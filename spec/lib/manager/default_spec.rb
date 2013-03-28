require 'spec_helper'

describe MicroQ::Manager::Default do
  let(:create) { -> { subject } }

  before do
    MicroQ.config.workers = 2
  end

  describe '.new' do
    before do
      MicroQ.config.workers = 4
    end

    it 'should create a default queue' do
      MicroQ::Queue::Default.should_receive(:new_link)

      create.call
    end

    it 'should create a worker links' do
      MicroQ::Worker::Standard.should_receive(:new_link).at_least(1)

      create.call
    end

    it 'should create config.workers number of links' do
      MicroQ::Worker::Standard.should_receive(:new_link).exactly(4)

      create.call
    end

    it 'should pass itself to the worker' do
      MicroQ::Worker::Standard.should_receive(:new_link).at_least(1) do |manager|
        manager.class.should == MicroQ::Manager::Default
        manager.wrapped_object.class.should == MicroQ::Manager::Default
      end

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
      subject.workers.collect {|w| w.wrapped_object.class}.uniq.should == [MicroQ::Worker::Standard]
    end
  end

  describe '#start' do
    it 'should not be performing' do
      subject.workers.each{|w| w.should_not_receive(:perform!) }

      subject.start
    end

    describe 'when the queue has dequeue-able items' do
      before do
        @item, @other_item = mock('Hash 1'), mock('Hash 2')
        @queue = mock(MicroQ::Queue::Default, :dequeue => [@item, @other_item])
        MicroQ::Queue::Default.stub(:new_link).and_return(@queue)

        @worker1 = mock(MicroQ::Worker::Standard, :perform! => nil)
        @worker2 = mock(MicroQ::Worker::Standard, :perform! => nil)
        MicroQ::Worker::Standard.stub(:new_link).and_return(@worker1, @worker2)
      end

      it 'should dequeue the number of free workers' do
        @queue.should_receive(:dequeue).with(2)

        subject.start
      end

      it 'should perform the items' do
        @worker1.should_receive(:perform!).with(@other_item)
        @worker2.should_receive(:perform!).with(@item)

        subject.start
      end

      describe 'when the manager is in SQS mode' do
        before do
          MicroQ.config['sqs?'] = true
        end

        it 'should not perform the items' do
          @queue.should_not_receive(:dequeue)
          [@worker1, @worker2].each {|w| w.should_not_receive(:perform!) }

          subject.start
        end
      end
    end
  end

  describe '#reinitialize' do
    let(:death) { -> { subject.reinitialize } }

    before do
      @queue = mock(MicroQ::Queue::Default, :alive? => true, :dequeue => [])
      MicroQ::Queue::Default.stub(:new_link).and_return(@queue)

      @worker1 = mock(MicroQ::Worker::Standard, :alive? => true, :perform! => nil)
      @worker2 = mock(MicroQ::Worker::Standard, :alive? => true, :perform! => nil)
      MicroQ::Worker::Standard.stub(:new_link).and_return(@worker1, @worker2)

      subject.start
    end

    it 'should have the items' do
      subject.queue.should == @queue
      subject.workers.should == [@worker1, @worker2]
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

    describe 'when a worker has died' do
      before do
        @worker2.stub(:alive?).and_return(false)

        @new_worker2 = mock(MicroQ::Worker::Standard)
        MicroQ::Worker::Standard.stub(:new_link).and_return(@new_worker2)
      end

      it 'should restart the dead worker' do
        MicroQ::Worker::Standard.should_receive(:new_link).and_return(@new_worker2)

        death.call
      end

      it 'should have the new worker' do
        death.call

        subject.workers.should == [@worker1, @new_worker2]
      end
    end
  end
end
