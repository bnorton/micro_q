require 'spec_helper'

describe MicroQ::Methods::Class do
  class MyWorker
    def self.seed
    end
  end

  shared_examples_for 'an async class' do
    before do
      @proxy = mock(MicroQ::Proxy::Class, :seed => nil)
      MicroQ::Proxy::Class.stub(:new).and_return(@proxy)
    end

    it 'should create a proxy' do
      MicroQ::Proxy::Class.should_receive(:new).and_return(@proxy)

      method.call
    end

    it 'should have the class' do
      MicroQ::Proxy::Class.should_receive(:new).with(hash_including(:class => subject)).and_return(@proxy)

      method.call
    end

    it 'should have a loader without a method' do
      MicroQ::Proxy::Class.should_receive(:new).with(hash_including(:loader => {})).and_return(@proxy)

      method.call
    end

    it 'should call the method' do
      @proxy.should_receive(:seed)

      method.call
    end

    it 'should pass arguments' do
      @proxy.should_receive(:seed).with(1, 2, 3)

      method.call(1, 2, 3)
    end
  end

  subject { MyWorker }

  it_behaves_like 'a_worker', 'seed'

  describe 'when an _async method is called' do
    let(:method) { lambda {|*args| subject.seed_async(*args) } }

    it_behaves_like 'an async class'
  end

  describe 'when calling to async.method proxy' do
    let(:method) { lambda {|*args| subject.async.seed(*args) } }

    it_behaves_like 'an async class'
  end
end
