require 'spec_helper'

describe MicroQ::Middleware::Server::Statistics, :middleware => true do
  describe '#call' do
    let(:foo) { mock("Foo", :bar => nil) }
    let(:block) { -> { foo.bar } }

    def call
      subject.call @worker, @payload, &block
    end

    before do
      @stats = mock(MicroQ::Statistics::Default, :incr => nil)
      MicroQ::Statistics::Default.stub(:stats).and_yield(@stats)
    end

    it 'should execute the block' do
      foo.should_receive(:bar)

      call
    end

    it 'should call into the statistics backend' do
      MicroQ::Statistics::Default.should_receive(:stats)

      call
    end

    it 'should log a completed message' do
      @stats.should_receive(:incr).with('messages:performed')

      call
    end

    it 'should log the completed class message' do
      @stats.should_receive(:incr).with("messages:#{@payload['class']}:performed")

      call
    end

    it 'should log the queue' do
      @stats.should_receive(:incr).with('queues:a-queue:performed')

      call
    end
  end
end
