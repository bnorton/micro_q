require 'spec_helper'

describe MicroQ::Methods::ActionMailer do
  class MyMailer < ActionMailer::Base
  end

  describe '.async' do
    let(:async) { -> { MyMailer.async } }

    it 'should create a mailer proxy' do
      MicroQ::Proxy::ActionMailer.should_receive(:new)

      async.call
    end

    it 'should have the class' do
      MicroQ::Proxy::ActionMailer.should_receive(:new).with(hash_including(:class => MicroQ::Wrapper::ActionMailer))

      async.call
    end

    it 'should have the base class' do
      MicroQ::Proxy::ActionMailer.should_receive(:new).with(hash_including(:base => MyMailer))

      async.call
    end
  end
end
