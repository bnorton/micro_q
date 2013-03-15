require 'spec_helper'

describe MicroQ::Middleware::Chain do
  class MyMiddleware; end

  describe MicroQ::Middleware::Chain::Base do
    subject { MicroQ::Middleware::Chain::Base.new }

    class OtherMiddleware; end

    describe '#add' do
      before do
        subject.add MyMiddleware
      end

      it 'should add the item' do
        subject.entries.should include(MyMiddleware)
      end

      it 'should be appended' do
        subject.entries.last.should == MyMiddleware
      end

      it 'should only add unique items' do
        subject.add MyMiddleware
        subject.add MyMiddleware

        subject.entries.uniq.should == subject.entries
      end
    end

    describe '#remove' do
      before do
        subject.add MyMiddleware

        subject.entries.should include(MyMiddleware)
        subject.remove MyMiddleware
      end

      it 'should remove the item' do
        subject.entries.should_not include(MyMiddleware)
      end
    end

    describe '#clear' do
      before do
        subject.add MyMiddleware
      end

      it 'should remove all entries' do
        subject.entries.should == [MyMiddleware]
        subject.clear

        subject.entries.should == []
      end
    end

    describe '#add_before' do
      class MiddleMiddleware; end

      def add_before
        subject.add_before(OtherMiddleware, MiddleMiddleware)
      end

      before do
        subject.clear
        subject.add MyMiddleware
        subject.add OtherMiddleware
      end

      it 'should not add nils' do
        subject.add_before MyMiddleware
        subject.entries.should have(2).items
      end

      it 'should add the middleware in the specified place' do
        add_before

        subject.entries.should == [
          MyMiddleware,
          MiddleMiddleware,
          OtherMiddleware
        ]
      end

      describe 'when relocating middleware' do
        before do
          subject.add MiddleMiddleware
        end

        it 'should move the middleware to the specified place' do
          subject.entries.should == [
            MyMiddleware,
            OtherMiddleware,
            MiddleMiddleware
          ]

          add_before

          subject.entries.should == [
            MyMiddleware,
            MiddleMiddleware,
            OtherMiddleware
          ]
        end
      end

      describe 'when adding multiple' do
        class SecondMiddleMiddleware; end

        def add_before
          subject.add_before(OtherMiddleware, MiddleMiddleware, SecondMiddleMiddleware)
        end

        it 'should add the middlewares in the specified place' do
          add_before

          subject.entries.should == [
            MyMiddleware,
            MiddleMiddleware,
            SecondMiddleMiddleware,
            OtherMiddleware
          ]
        end
      end
    end

    describe '#add_after' do
      class MiddleMiddleware; end

      def add_after
        subject.add_after(OtherMiddleware, MiddleMiddleware)
      end

      before do
        subject.clear
        subject.add MyMiddleware
        subject.add OtherMiddleware
      end

      it 'should not add nils' do
        subject.add_after MyMiddleware
        subject.entries.should have(2).items
      end

      it 'should add the middleware in the specified place' do
        add_after

        subject.entries.should == [
          MyMiddleware,
          OtherMiddleware,
          MiddleMiddleware
        ]
      end

      describe 'when relocating middleware' do
        before do
          subject.add_before MyMiddleware, MiddleMiddleware
        end

        it 'should move the middleware to the specified place' do
          subject.entries.should == [
            MiddleMiddleware,
            MyMiddleware,
            OtherMiddleware
          ]

          add_after

          subject.entries.should == [
            MyMiddleware,
            OtherMiddleware,
            MiddleMiddleware
          ]
        end
      end

      describe 'when adding multiple' do
        class SecondMiddleMiddleware; end

        def add_after
          subject.add_after(OtherMiddleware, MiddleMiddleware, SecondMiddleMiddleware)
        end

        it 'should add the middlewares in the specified place' do
          add_after

          subject.entries.should == [
            MyMiddleware,
            OtherMiddleware,
            MiddleMiddleware,
            SecondMiddleMiddleware
          ]
        end
      end
    end
  end

  describe '.server' do
    it 'should expose the server middleware' do
      subject.server.class.should == MicroQ::Middleware::Chain::Server
    end

    it 'should cache the object' do
      subject.server.object_id.should == subject.server.object_id
    end

    describe 'defaults' do
      [MicroQ::Middleware::Server::Statistics,
       MicroQ::Middleware::Server::Timeout,
       MicroQ::Middleware::Server::Retry,
       MicroQ::Middleware::Server::Connection].each do |klass|
        it "should include #{klass}" do
          subject.server.entries.should include(klass)
        end
      end

      it 'should be 4 items long' do
        subject.server.entries.should have(4).items
      end
    end
  end

  describe '.client' do
    it 'should expose the server middleware' do
      subject.client.class.should == MicroQ::Middleware::Chain::Client
    end

    it 'should cache the object' do
      subject.client.object_id.should == subject.client.object_id
    end

    describe 'defaults' do
      [MicroQ::Middleware::Client::Statistics].each do |klass|
        it "should include #{klass}" do
          subject.client.entries.should include(klass)
        end
      end

      it 'should be 1 item long' do
        subject.client.entries.should have(1).item
      end
    end
  end

  describe '.call' do
    let(:worker) { MyWorker.new }
    let(:payload) { {'class' => 'MyWorker'} }

    class MyWorker
    end

    describe 'server' do
      def call
        subject.server.call(worker, payload) { }
      end

      it 'should make a new timeout instance' do
        MicroQ::Middleware::Server::Timeout.should_receive(:new).and_call_original

        call
      end

      it 'should make a new retry instance' do
        MicroQ::Middleware::Server::Retry.should_receive(:new).and_call_original

        call
      end

      it 'should make a new connections instance' do
        MicroQ::Middleware::Server::Connection.should_receive(:new).and_call_original

        call
      end

      it 'should make a new statistics instance' do
        MicroQ::Middleware::Server::Statistics.should_receive(:new).and_call_original

        call
      end

      it 'should not remove the Statistics' do
        subject.server.remove(MicroQ::Middleware::Server::Statistics)

        subject.server.entries.should include(MicroQ::Middleware::Server::Statistics)
      end

      it 'should call the timeout middleware' do
        @timeout = mock(MicroQ::Middleware::Server::Timeout)
        MicroQ::Middleware::Server::Timeout.stub(:new).and_return(@timeout)

        @timeout.should_receive(:call).with(worker, payload)

        call
      end

      it 'should call the retry middleware' do
        @retry = mock(MicroQ::Middleware::Server::Retry)
        MicroQ::Middleware::Server::Retry.stub(:new).and_return(@retry)

        @retry.should_receive(:call).with(worker, payload)

        call
      end

      it 'should call the connection middleware' do
        @connection = mock(MicroQ::Middleware::Server::Connection)
        MicroQ::Middleware::Server::Connection.stub(:new).and_return(@connection)

        @connection.should_receive(:call).with(worker, payload)

        call
      end

      it 'should call the statistics middleware' do
        statistics = mock(MicroQ::Middleware::Server::Connection)
        MicroQ::Middleware::Server::Connection.stub(:new).and_return(statistics)

        statistics.should_receive(:call).with(worker, payload)

        call
      end
    end

    describe 'client' do
      let(:opts) { mock('options') }

      def call
        subject.client.call(payload, opts) { }
      end

      it 'should make a new statistics instance' do
        MicroQ::Middleware::Client::Statistics.should_receive(:new).and_call_original

        call
      end

      it 'should not remove the Statistics' do
        subject.client.remove(MicroQ::Middleware::Client::Statistics)

        subject.client.entries.should include(MicroQ::Middleware::Client::Statistics)
      end

      it 'should call the statistics middleware' do
        statistics = mock(MicroQ::Middleware::Client::Statistics)
        MicroQ::Middleware::Client::Statistics.stub(:new).and_return(statistics)

        statistics.should_receive(:call).with(payload, opts)

        call
      end
    end
  end
end
