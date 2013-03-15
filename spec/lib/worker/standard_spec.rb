require 'spec_helper'

describe MicroQ::Worker::Standard do
  let(:worker) { {'class' => 'MyWorker', 'args' => [1, 'value']} }
  let(:other_worker) { {'class' => 'MyWorker', 'method' => 'process', 'args' => [2, 'other-value']} }

  let(:manager) { mock(MicroQ::Manager::Default, :work_done! => nil) }
  subject { MicroQ::Worker::Standard.new(manager) }

  class MyWorker
    def self.seed(*) end
    def ar_perform(*) end
    def perform(*) end
    def process(*) end
  end

  describe '#perform' do
    def perform(item)
      subject.perform(item)
    end

    it 'should call the methods' do
      MyWorker.any_instance.should_receive(:perform).with(1, 'value')
      MyWorker.any_instance.should_receive(:process).with(2, 'other-value')

      perform(worker); perform(other_worker)
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

    it 'should inform the manager that it finished' do
      manager.should_receive(:work_done!).with(subject)

      perform(worker)
    end

    describe 'when using the class loader' do
      let(:class_worker) { {'class' => 'MyWorker', 'method' => 'seed', 'args' => [3, 45], 'loader' => {}} }

      it 'should not create an instance' do
        MyWorker.should_not_receive(:new)

        perform(class_worker)
      end

      it 'should call the method' do
        MyWorker.should_receive(:seed)

        perform(class_worker)
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
        worker = mock(MyWorker)
        MyWorker.stub(:find).with(456).and_return(worker)

        worker.should_receive(:ar_perform).with(1, 2)

        perform(ar_worker)
      end
    end
  end
end
