require 'spec_helper'

describe MicroQ::SqsClient, :aws => true do
  let(:url) { 'http://the.queue/' }

  subject { MicroQ::SqsClient.new('low') }

  before do
    MicroQ.config.env = 'dev-env'

    @client = mock(AWS::SQS::Client, :receive_message => {}, :create_queue => {:queue_url => url})
    AWS::SQS::Client.stub(:new).and_return(@client)
  end

  describe '.new' do
    it 'should create the queue' do
      @client.should_receive(:create_queue).and_return({})

      subject
    end

    it 'should prefix the name with the environment' do
      @client.should_receive(:create_queue).with(
        :queue_name => 'dev-env_low'
      ).and_return({})

      subject
    end

    it 'should have the url' do
      subject.url.should == url
    end

    describe 'when the call fails' do
      before do
        @client.stub(:create_queue).and_raise
      end

      it 'should error' do
        expect {
          subject
        }.to raise_error
      end
    end
  end

  describe '#messages' do
    let(:messages) { subject.messages }

    it 'should be an empty' do
      messages.should == []
    end

    it 'should connect to the api for reading messages' do
      @client.should_receive(:receive_message)

      messages
    end

    it 'should have the queue url' do
      @client.should_receive(:receive_message).with(hash_including(:queue_url => url))

      messages
    end

    it 'should timeout after 10 seconds' do
      @client.should_receive(:receive_message).with(hash_including(:wait_time_seconds => 10))

      messages
    end

    it 'should request 10 items' do
      @client.should_receive(:receive_message).with(hash_including(:max_number_of_messages => 10))

      messages
    end

    it 'should make message available again after 5 minutes' do
      @client.should_receive(:receive_message).with(hash_including(:visibility_timeout => 5 * 60))

      messages
    end

    describe 'when messages are returned (body as json)' do
      let(:response) do
        { :messages => 3.times.map {|i|
          {
            :body => {:id => i}.to_json,
            :message_id => "id:#{i*5}",
            :receipt_handle => "hand:#{i+10}"
          }
        }}
      end

      before do
        @client.stub(:receive_message).and_return(response)
      end

      it 'should return the messages' do
        messages.map {|m| m['id']}.should == [0, 1, 2]
      end

      it 'should merge in the message id' do
        messages.map {|m| m['sqs_id']}.should == ['id:0', 'id:5', 'id:10']
      end

      it 'should merge in the message id' do
        messages.map {|m| m['sqs_handle']}.should == ['hand:10', 'hand:11', 'hand:12']
      end

      it 'should merge in the queue url' do
        messages.map {|m| m['sqs_queue']}.uniq.should == [url]
      end
    end
  end

  describe '#messages_create' do
    let(:message) { {:class => 'MyWorker', :args => ['hi']} }
    let(:send_message) { subject.messages_create(message) }

    before do
      @response = {:message_id => '10'}
      @client.stub(:send_message).and_return(@response)
    end

    it 'should send the message' do
      @client.should_receive(:send_message).and_return(@response)

      send_message
    end

    it 'should send it for the queue' do
      @client.should_receive(:send_message).with(hash_including(:queue_url => url)).and_return(@response)

      send_message
    end

    it 'should send it for the queue' do
      @client.should_receive(:send_message).with(hash_including(:message_body => message.to_json)).and_return(@response)

      send_message
    end

    it 'should not delay the message' do
      @client.should_receive(:send_message).with(hash_excluding(:delay_seconds)).and_return(@response)

      send_message
    end

    it 'should return the message id' do
      send_message.should == '10'
    end

    describe 'when the message is to be run later' do
      before do
        message['run_at'] = (Time.now + 60 * 60)
      end

      it 'should set the delay for sqs' do
        @client.should_receive(:send_message).with(hash_including(:delay_seconds => 60*60)).and_return(@response)

        send_message
      end
    end
  end
end
