require 'spec_helper'

describe MicroQ::Fetcher::Sqs do
  let(:queue) { mock(MicroQ::Queue::Sqs, :receive_messages! => nil) }

  subject { MicroQ::Fetcher::Sqs.new(:low, queue) }

  before do
    @client = mock(MicroQ::SqsClient, :messages => [])
    MicroQ::SqsClient.stub(:new => @client)
  end

  describe '.new' do
    it 'should have the queue name' do
      subject.name.should == 'low'
    end
  end

  describe '#start' do
    it 'should create an sqs client' do
      MicroQ::SqsClient.should_receive(:new).with('low').and_return(@client)

      subject.start
    end

    describe 'when called again' do
      it 'should create an sqs client' do
        MicroQ::SqsClient.should_receive(:new).and_return(@client)
        subject.start

        MicroQ::SqsClient.rspec_verify
        MicroQ::SqsClient.rspec_reset

        MicroQ::SqsClient.should_not_receive(:new)

        subject.start
      end
    end

    it 'should request messages from the queue' do
      @client.should_receive(:messages)

      subject.start
    end

    describe 'when there are messages in the queue' do
      let(:messages) { 2.times.map {|i| mock("message_#{i}") }}

      before do
        @client.stub(:messages).and_return(messages)
      end

      it 'should hand of the messages to the manager' do
        queue.should_receive(:receive_messages!).with(messages)

        subject.start
      end
    end
  end

  describe '#add_message' do
    let(:message) { {'class' => 'FooBar'} }
    let(:add_message) { subject.add_message(message) }

    it 'should create the message' do
      @client.should_receive(:messages_create).with(message)

      add_message
    end

    describe 'when the message has an associated time' do
      let(:add_message) { subject.add_message(message, Time.now.to_i) }

      it 'should send the time' do
        @client.should_receive(:messages_create).with(message.merge('run_at' => Time.now.to_i))

        add_message
      end
    end
  end
end
