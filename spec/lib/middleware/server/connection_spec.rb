require 'spec_helper'
require 'active_record'

describe MicroQ::Middleware::Server::Connection, :middleware => true do
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

    describe 'active_record' do
      it 'should clear active connections' do
        ActiveRecord::Base.should_receive(:clear_active_connections!)

        call
      end

      describe 'when the job raises an exception' do
        let(:block) { -> { raise } }

        it 'should error' do
          expect {
            call
          }.to raise_error
        end

        it 'should clear active connections' do
          ActiveRecord::Base.should_receive(:clear_active_connections!)

          safe(:call)
        end
      end
    end

  end
end
