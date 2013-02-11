require 'spec_helper'
require 'active_record'
require 'micro_q/methods/active_record'

describe MicroQ::Methods::ActiveRecord, :active_record => true do
  class Repository < ActiveRecord::Base
    def id
      456
    end

    def process
    end
  end

  shared_examples_for 'an async AR instance' do
    before do
      @proxy = mock(MicroQ::Proxy::Instance, :process => nil)
      MicroQ::Proxy::Instance.stub(:new).and_return(@proxy)
    end

    it 'should create an instance proxy' do
      MicroQ::Proxy::Instance.should_receive(:new).and_return(@proxy)

      method.call
    end

    it 'should have the class' do
      MicroQ::Proxy::Instance.should_receive(:new).with(hash_including(:class => subject.class)).and_return(@proxy)

      method.call
    end

    it 'should have the activerecord find with the record id' do
      MicroQ::Proxy::Instance.should_receive(:new).with(hash_including(:loader => {:method => 'find', :args => [456]})).and_return(@proxy)

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

  subject { Repository.new }

  it_behaves_like 'a_worker', 'process'

  describe 'when an _async method is called' do
    let(:method) { lambda {|*args| subject.process_async(*args) } }

    it_behaves_like 'an async AR instance'
  end

  describe 'when calling to async.method proxy' do
    let(:method) { lambda {|*args| subject.async.process(*args) } }

    it_behaves_like 'an async AR instance'
  end
end
