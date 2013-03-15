require 'spec_helper'

describe MicroQ::Middleware::Client::Statistics, :middleware => true do
  describe '#call' do
    let(:foo) { mock('Foo', :bar => nil) }
    let(:block) { -> { foo.bar } }

    def call
      subject.call @payload, {}, &block
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

    it 'should log a enqueued message' do
      @stats.should_receive(:incr) do |*args|
        args.should include('messages:enqueued')
      end

      call
    end

    it 'should log the enqueued class message' do
      @stats.should_receive(:incr) do |*args|
        args.should include("messages:#{@payload['class']}:enqueued")
      end

      call
    end

    it 'should log the queue' do
      @stats.should_receive(:incr) do |*args|
        args.should include('queues:a-queue:enqueued')
      end

      call
    end
  end
end
