require 'spec_helper'

describe MicroQ::Fetcher::Sqs do
  let(:queue) { mock(MicroQ::Queue::Sqs, :receive_messages! => nil) }

  subject { MicroQ::Fetcher::Sqs.new(:low, queue) }

  describe '.new' do
    it 'should have the queue name' do
      subject.name.should == 'low'
    end
  end

  describe '#start' do
    before do
      @client = mock(MicroQ::SqsClient, :messages => [])
      MicroQ::SqsClient.stub(:new => @client)
    end

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
end
