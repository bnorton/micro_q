require 'spec_helper'

describe MicroQ::Proxy::ActionMailer do
  let(:method) { lambda {|*args| subject.mail_me(*args) } }
  let(:options) { { :class => MicroQ::Wrapper::ActionMailer, :base => MyMailer } }

  class MyMailer < ActionMailer::Base
  end

  subject { MicroQ::Proxy::ActionMailer.new(options) }

  describe 'method invocations' do
    let(:method) { -> { subject.some_method(1, 2) } }

    it 'should push the message' do
      MicroQ.should_receive(:push)

      method.call
    end

    it 'should have the class' do
      MicroQ.should_receive(:push).with(hash_including(:class => MicroQ::Wrapper::ActionMailer))

      method.call
    end

    it 'should have the method' do
      MicroQ.should_receive(:push).with(hash_including(:method => 'perform'))

      method.call
    end

    it 'should have the args' do
      MicroQ.should_receive(:push).with(hash_including(:args => ['MyMailer', 'some_method', 1, 2]))

      method.call
    end

    describe 'when performing at a specific time' do
      before do
        options[:at] = Time.now + 60
      end

      it 'should push with the right \'when\' key' do
        MicroQ.should_receive(:push).with(anything, :when => (Time.now + 60).to_i)

        method.call
      end
    end
  end
end
