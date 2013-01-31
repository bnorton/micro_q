require 'spec_helper'

describe MicroQ::Middleware::Chain do
  describe MicroQ::Middleware::Chain::Base do
    subject { MicroQ::Middleware::Chain::Base.new }

    describe '#add' do
      class MyMiddleware; end

      before do
        subject.add MyMiddleware
      end

      it 'should add the item' do
        subject.entries.should include(MyMiddleware)
      end

      it 'should be appended' do
        subject.entries.last.should == MyMiddleware
      end
    end

    describe '#remove' do
      class MyMiddleware; end

      before do
        subject.add MyMiddleware

        subject.entries.should include(MyMiddleware)
        subject.remove MyMiddleware
      end

      it 'should remove the item' do
        subject.entries.should_not include(MyMiddleware)
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
      [MicroQ::Middleware::Server::Retry].each do |klass|
        it "should include #{klass}" do
          subject.server.entries.should include(klass)
        end
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

    it "should be empty" do
      subject.client.entries.should == []
    end
  end
end
