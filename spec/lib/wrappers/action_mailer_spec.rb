require 'spec_helper'

describe MicroQ::Wrapper::ActionMailer do
  class MyMailer
    def self.mail_me
    end
  end

  describe '#perform' do
    let(:mail) { mock('email', :deliver => nil) }

    def perform
      subject.perform('MyMailer', 'mail_me', 1, 2)
    end

    before do
      MyMailer.stub(:mail_me).and_return(mail)
    end

    it 'should call the mailer method' do
      MyMailer.should_receive(:mail_me).and_return(mail)

      perform
    end

    it 'should pass the arguments' do
      MyMailer.should_receive(:mail_me).with(1, 2).and_return(mail)

      perform
    end

    it 'should deliver the email' do
      mail.should_receive(:deliver)

      perform
    end

    describe 'when the email does not work' do
      let(:mail) { mock('email without deliver') }

      before do
        mail.stub(:respond_to?).with(:deliver).and_return(false)
      end

      it 'should not error' do
        expect {
          perform
        }.not_to raise_error
      end

      it 'should not deliver the message' do
        mail.should_not_receive(:deliver)

        perform
      end
    end
  end
end
