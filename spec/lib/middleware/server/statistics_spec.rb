require 'spec_helper'

describe MicroQ::Middleware::Server::Statistics, :middleware => true do
  describe '#call' do
    let(:foo) { mock("Foo", :bar => nil) }
    let(:block) { -> { foo.bar } }

    def call
      subject.call @worker, @payload, &block
    end

    it 'should execute the block' do
      foo.should_receive(:bar)

      call
    end
  end
end
