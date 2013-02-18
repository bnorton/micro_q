require 'spec_helper'

describe MicroQ::Middleware::Server::Timeout, :middleware => true do
  describe '#call' do
    let(:foo) { mock("Foo", :bar => nil) }
    let(:block) { -> { foo.bar } }

    def call
      subject.call @worker, @payload, &block
    end

    before do
      Timecop.freeze(DateTime.now)
    end

    it 'should execute the block' do
      foo.should_receive(:bar)

      call
    end

    it 'should timeout after 10 minutes' do
      subject.should_receive(:timeout).with(10 * 60)

      call
    end

    describe 'when the timeout is set' do
      before do
        @payload.merge!('timeout' => 60)
      end

      it 'should timeout after 60 seconds' do
        subject.should_receive(:timeout).with(60)

        call
      end
    end
  end
end
