require 'spec_helper'

describe MicroQ::DSL do
  describe '.worker' do
    class OtherWorker
      worker :update
    end

    it 'should add the method' do
      Object.should be_respond_to(:worker)
    end

    it 'should include the dsl module' do
      Object.should be_is_a(MicroQ::DSL)
    end

    it 'should add the async_perform method' do
      OtherWorker.should be_respond_to(:async_perform)
    end

    it 'should add async_ prefixed method when given them' do
      OtherWorker.should be_respond_to(:async_update)
    end

    describe 'when calling the async_ method' do
      let(:method) { ->(*args) { OtherWorker.async_perform(*args) } }

      before do
        @proxy = mock(MicroQ::Proxy::Instance, :perform => nil)
        MicroQ::Proxy::Instance.stub(:new).and_return(@proxy)
      end

      it 'should create a proxy' do
        MicroQ::Proxy::Instance.should_receive(:new).and_return(@proxy)

        method.call
      end

      it 'should have the class' do
        MicroQ::Proxy::Instance.should_receive(:new).with(hash_including(:class => OtherWorker)).and_return(@proxy)

        method.call
      end

      it 'should call the perform method' do
        @proxy.should_receive(:perform)

        method.call
      end

      it 'should have given arguments' do
        @proxy.should_receive(:perform).with('hey yay', 4)

        method.call('hey yay', 4)
      end
    end

    describe 'when calling the async_something method' do
      let(:method) { ->(*args) { OtherWorker.async_update(*args) } }

      before do
        @proxy = mock(MicroQ::Proxy::Instance, :update => nil)
        MicroQ::Proxy::Instance.stub(:new).and_return(@proxy)
      end

      it 'should have the class' do
        MicroQ::Proxy::Instance.should_receive(:new).with(hash_including(:class => OtherWorker)).and_return(@proxy)

        method.call
      end

      it 'should call the update method' do
        @proxy.should_receive(:update)

        method.call
      end

      it 'should have given arguments' do
        @proxy.should_receive(:update).with('hey yay', 12)

        method.call('hey yay', 12)
      end
    end

    describe 'when given custom options' do
      class OneWorker; worker :one_method end
      class OptionWorker
        worker :method_name, :queue => 'my-queue', :option => 'value'
        worker :other_method, :queue => 'my-queue', :option => 'value'
      end

      it 'should have the async_ methods' do
        OptionWorker.should be_respond_to(:async_method_name)
        OptionWorker.should be_respond_to(:async_other_method)
      end

      it 'should store the options' do
        OptionWorker.microq_options[:queue].should == 'my-queue'
        OptionWorker.microq_options[:option].should == 'value'
      end

      it 'should merge the given methods' do
        OptionWorker.microq_options[:methods].should == [:perform, :method_name, :other_method]
      end

      it 'should not bleed methods' do
        OneWorker.microq_options[:methods].should == [:perform, :one_method]
      end
    end
  end
end
