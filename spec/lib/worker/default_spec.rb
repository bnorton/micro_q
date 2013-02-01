require 'spec_helper'

describe MicroQ::Worker::Default do
  let(:worker) { {'class' => 'MyWorker', 'args' => [1, 'value']} }
  let(:other_worker) { {'class' => 'MyWorker', 'method' => 'process', 'args' => [2, 'other-value']} }

  class MyWorker
    attr_reader :performed, :processed

    def perform(*args)
      "PERFORMED! #{args.inspect}"
    end

    def process(*args)
      "PROCESSED! #{args.inspect}"
    end
  end

  describe '#perform' do
    def perform(item)
      subject.perform(item)
    end

    it 'should call the method' do
      perform(worker).should == 'PERFORMED! [1, "value"]'
      perform(other_worker).should == 'PROCESSED! [2, "other-value"]'
    end

    it 'should process the middleware chain' do
      MicroQ.config.middleware.server.should_receive(:call) do |w, payload|
        w.class.should == MyWorker

        payload['class'].should == 'MyWorker'
        payload['args'].should == [1, 'value']
      end

      perform(worker)
    end

    it 'should process the middleware chain for both workers' do
      MicroQ.config.middleware.server.should_receive(:call) do |w, payload|
        w.class.should == MyWorker

        payload['class'].should == 'MyWorker'
        payload['args'].should == [2, 'other-value']
      end

      perform(other_worker)
    end
  end
end
