require 'spec_helper'

describe MicroQ::Worker::Standard do
  let(:worker) { {'class' => 'MyWorker', 'args' => [1, 'value']} }
  let(:other_worker) { {'class' => 'MyWorker', 'method' => 'process', 'args' => [2, 'other-value']} }

  class MyWorker
    def self.seed(*args); "SEEDED #{args.inspect}" end
    def ar_perform(*args);"AR PERFORM! #{args.inspect}" end
    def perform(*args);   "PERFORMED! #{args.inspect}" end
    def process(*args);   "PROCESSED! #{args.inspect}" end
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
      MicroQ.middleware.server.should_receive(:call) do |w, payload|
        w.class.should == MyWorker

        payload['class'].should == 'MyWorker'
        payload['args'].should == [1, 'value']
      end

      perform(worker)
    end

    it 'should process the middleware chain for both workers' do
      MicroQ.middleware.server.should_receive(:call) do |w, payload|
        w.class.should == MyWorker

        payload['class'].should == 'MyWorker'
        payload['args'].should == [2, 'other-value']
      end

      perform(other_worker)
    end

    describe 'when using the class loader' do
      let(:class_worker) { {'class' => 'MyWorker', 'method' => 'seed', 'args' => [3, 45], 'loader' => {}} }

      it 'should not create an instance' do
        MyWorker.should_not_receive(:new)

        perform(class_worker)
      end

      it 'should call the method' do
        perform(class_worker).should == "SEEDED [3, 45]"
      end
    end

    describe 'when the model has a custom \'loader\'' do
      let(:ar_worker) { {'class' => 'MyWorker', 'method' => 'ar_perform', 'args' => [1, 2], 'loader' => {'method' => 'find', 'args' => [456]}} }

      before do
        @model = mock('Model', :ar_perform => nil)
        MyWorker.stub(:find).with(456).and_return(@model)
      end

      it 'should load the class' do
        MyWorker.should_receive(:find).with(456).and_return(@model)

        perform(ar_worker)
      end

      it 'should call the method a' do
        @model.should_receive(:ar_perform).with(1, 2)

        perform(ar_worker)
      end

      it 'should call the method b' do
        worker = MyWorker.new
        MyWorker.stub(:find).with(456).and_return(worker)

        perform(ar_worker).should == 'AR PERFORM! [1, 2]'
      end
    end
  end
end
