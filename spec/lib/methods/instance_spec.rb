require 'spec_helper'

describe MicroQ::Methods::Instance do
  class MyWorker
    def process
    end
  end

  shared_examples_for 'an async instance' do
    before do
      @proxy = mock(MicroQ::Proxy::Instance, :process => nil)
      MicroQ::Proxy::Instance.stub(:new).and_return(@proxy)
    end

    it 'should create a proxy' do
      MicroQ::Proxy::Instance.should_receive(:new).and_return(@proxy)

      method.call
    end

    it 'should have the class' do
      MicroQ::Proxy::Instance.should_receive(:new).with(hash_including(:class => subject.class)).and_return(@proxy)

      method.call
    end

    it 'should call the method' do
      @proxy.should_receive(:process)

      method.call
    end

    it 'should pass arguments' do
      @proxy.should_receive(:process).with(1, 2, 3)

      method.call(1, 2, 3)
    end
  end

  subject { MyWorker.new }

  it_behaves_like 'a_worker', 'process'

  describe 'when calling to async.method proxy' do
    let(:method) { lambda {|*args| subject.async.process(*args) } }

    it_behaves_like 'an async instance'
  end
end
