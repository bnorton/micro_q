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

      it 'should add the items to the currently working items' do
        subject.start

        subject.current[@worker1].should == @other_item
        subject.current[@worker2].should == @item
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

        describe 'when in worker mode' do
          before do
            MicroQ.config['worker_mode?'] = true
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
        end
      end
    end
  end

  describe '#reinitialize' do
    let(:current) { subject.current }

    let(:death) { -> { subject.reinitialize(@worker2, Exception.new('worker2 crashed')) } }

    before do
      @queue = mock(MicroQ::Queue::Default, :alive? => true, :dequeue => [], :finished! => nil, :respond_to? => true)
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

      describe 'when a busy worker has died' do
        let(:message) { mock('message') }

        before do
          current[@worker2] = message
          subject.wrapped_object.instance_variable_set(:@busy, [@worker2])
        end

        it 'should restart the dead worker' do
          MicroQ::Worker::Standard.should_receive(:new_link).and_return(@new_worker2)

          death.call
        end

        it 'should remove the worker from the busy list' do
          death.call

          subject.wrapped_object.instance_variable_get(:@busy).should == []
        end

        it 'should have the new worker' do
          death.call

          subject.workers.should == [@worker1, @new_worker2]
        end

        it 'should remove the worker from current' do
          current.should have_key(@worker2)
          death.call

          current.should_not have_key(@worker2)
        end

        it 'should finish the message with the queue' do
          @queue.should_receive(:finished!).with(message)

          death.call
        end

        describe 'when the queue does not respond to finished' do
          before do
            @queue.stub(:respond_to?).with(:finished).and_return(false)
          end

          it 'should not call it' do
            @queue.should_not_receive(:finished!)

            death.call
          end
        end
      end

      describe 'when in SQS mode' do
        before do
          MicroQ.config['sqs?'] = true
        end

        it 'should have the original items' do
          death.call

          subject.queue.should == @queue
          subject.workers.should == [@worker1, @worker2]
        end
      end
    end
  end

  describe '#work_done' do
    let(:message) { mock('message') }
    let(:current) { subject.current }

    let(:work_done) { subject.work_done(@worker) }

    before do
      @worker = mock('worker')
      @queue = mock(MicroQ::Queue::Default, :respond_to? => true, :finished! => nil)
      MicroQ::Queue::Default.stub(:new_link).and_return(@queue)

      subject.wrapped_object.instance_variable_set(:@busy, [@worker])
      current[@worker] = message
    end

    it 'should remove the worker from busy' do
      work_done

      subject.busy.should == []
    end

    it 'should add the worker to workers' do
      work_done

      subject.workers.should include(@worker)
    end

    it 'should remove the worker from current' do
      current.should have_key(@worker)
      work_done

      current.should_not have_key(@worker)
    end

    it 'should finish the message with the queue' do
      @queue.should_receive(:finished!).with(message)

      work_done
    end

    describe 'when the queue does not respond to finished' do
      before do
        @queue.stub(:respond_to?).with(:finished).and_return(false)
      end

      it 'should not call it' do
        @queue.should_not_receive(:finished!)

        work_done
      end
    end
  end
end
