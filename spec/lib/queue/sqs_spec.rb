require 'spec_helper'

describe MicroQ::Queue::Sqs do
  let(:item) { { 'class' => 'MyWorker', 'args' => [4] } }

  describe '.new' do
    it 'should create three fetchers' do
      MicroQ::Fetcher::Sqs.should_receive(:new_link).exactly(3)

      subject
    end

    it 'should send the current actor along too' do
      MicroQ::Fetcher::Sqs.should_receive(:new_link).exactly(3).with(anything, subject)

      subject
    end

    it 'should have the fetchers' do
      subject.fetchers.map(&:class).uniq.should == [MicroQ::Fetcher::Sqs]
    end
  end

  describe '#receive_messages' do
    let(:messages) { 3.times.map {|i| mock("message_#{i}")} }

    it 'should have no messages' do
      subject.messages.should == []
    end

    describe 'when messages have given back' do
      before do
        subject.receive_messages(messages.first(1))
      end

      it 'should have the messages' do
        subject.messages.should == [messages.first]
      end

      describe 'when more messages have been received' do
        before do
          subject.receive_messages(messages.last(2))
        end

        it 'should have the messages' do
          subject.messages.should == messages
        end
      end
    end
  end

  describe '#sync_push' do
      it_behaves_like 'Queue#sync_push'

    describe 'when given the \'when\' key' do
      let(:worker) { [item, { 'when' => (Time.now + 100).to_i }] }

      it 'should schedule the item for later' do
        subject.sync_push(*worker)

        subject.later.should include(worker.last.merge('worker' => item))
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

      it 'should schedule the item for later' do
        subject.sync_push(*worker)

        subject.later.should include({'when' => worker.last[:when]}.merge('worker' => item))
      end
    end
  end

  describe '#push' do
    before do
      @async = mock(Celluloid::ActorProxy)
      subject.stub(:async).and_return(@async)
    end

    it 'should asynchronously push the item' do
      @async.should_receive(:sync_push).with(item)

      subject.push(item)
    end
  end

  describe '#dequeue' do
    let(:items) { 2.times.map {|i| { 'class' => 'SqsWorker', 'args' => [i] }} }
    let(:item) { items.first }

    class SqsWorker
      def perform(*)
      end
    end

    describe 'when there are messages' do
      before do
        subject.messages = items.map(&:dup)
      end

      it 'should return the limited number of items' do
        subject.dequeue(1).should == [items.last]
      end

      it 'should remove the item from the list' do
        subject.dequeue.should == items.reverse

        subject.messages.should == []
      end
    end

    describe 'when there are many messages' do
      let(:messages) do
        5.times.collect {|i|
          item.dup.tap {|it| it['args'] = [i]}
        }
      end

      before do
        subject.messages = messages.map(&:dup)
      end

      it 'should return up to the limit number of items' do
        subject.dequeue(4).should == messages.last(4).reverse

        subject.messages.should include(messages.first)
        subject.dequeue.should == messages.first(1)
      end

      it 'should remove the items' do
        subject.dequeue.should == messages.reverse
        subject.dequeue.should == []

        subject.messages.should == []
      end
    end
  end
end
