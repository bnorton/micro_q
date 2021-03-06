require 'spec_helper'

describe MicroQ::Middleware::Server::Retry, :middleware => true do
  describe '#call' do
    let(:foo) { mock('Foo', :bar => nil) }
    let(:block) { -> { foo.bar } }

    def call
      subject.call @worker, @payload, &block
    end

    it 'should execute the block' do
      foo.should_receive(:bar)

      call
    end

    describe 'when the block raises an Exception' do
      let(:exception) { Exception.new('an exception') }
      let(:block) { -> { raise exception } }

      before do
        @stats = mock(MicroQ::Statistics::Default, :incr => nil)
        MicroQ::Statistics::Default.stub(:stats).and_yield(@stats)
      end

      describe 'when retry is disabled' do
        before do
          @payload['retry'] = false
        end

        it 'should re-raise the error' do
          expect {
            call
          }.to raise_error(Exception, 'an exception')
        end

        it 'should not push the message' do
          MicroQ.should_not_receive(:push)

          expect {
            call
          }.to raise_error(Exception, 'an exception')
        end
      end

      describe 'when retry is enabled' do
        before do
          @payload['retry'] = true
        end

        it 'should re-raise the error' do
          expect {
            call
          }.to raise_error(Exception, 'an exception')
        end

        it 'should log the retry' do
          @stats.should_receive(:incr) do |*args|
            args.should include('messages:retry')
          end

          safe(:call)
        end

        it 'should log the class\' retry' do
          @stats.should_receive(:incr) do |*args|
            args.should include("messages:#{@payload['class']}:retry")
          end

          safe(:call)
        end

        it 'should log the queues\' retry' do
          @stats.should_receive(:incr) do |*args|
            args.should include('queues:a-queue:retry')
          end

          safe(:call)
        end

        it 'should increment the number of retries' do
          @payload['retried'].should be_nil

          safe(:call); @payload['retried']['count'].should == 1
          safe(:call); @payload['retried']['count'].should == 2
        end

        it 'should update the retry when time' do
          @payload['retried'] = { 'count' => 1 }

          expect {
            safe(:call)
          }.to change { @payload['retried']['when'] }

          expect {
            safe(:call)
          }.to change { @payload['retried']['when'] }
        end

        it 'should set the last retry time' do
          Timecop.freeze do
            safe(:call)

            @payload['retried']['at'].should == Time.now
          end
        end

        it 'should push the message back onto the queue' do
          MicroQ.should_receive(:push) do |payload, *|
            payload.should == @payload
          end

          safe(:call)
        end

        it 'should enqueue for the next retry time' do
          Timecop.freeze do
            MicroQ.should_receive(:push).with(anything, hash_including('when'))

            safe(:call)
          end
        end

        describe 'when the message has retried 25 times' do
          before do
            @payload['retried'] = { 'count' => 25 }
          end

          it 'should not push the message' do
            MicroQ.should_not_receive(:push)

            expect {
              call
            }.to raise_error(Exception, 'an exception')
          end
        end

        describe 'when the message should retry 10 times' do
          before do
            @payload['retry'] = 10
          end

          it 'should retry the message' do
            MicroQ.should_receive(:push)

            safe(:call)
          end

          describe 'when the message has retried 10 times' do
            before do
              @payload['retried'] = { 'count' => 10 }
            end

            it 'should not push the message' do
              MicroQ.should_not_receive(:push)

              expect {
                call
              }.to raise_error(Exception, 'an exception')
            end

            describe 'when the retry count is a string' do
              before do
                @payload['retry'] = '10'
              end

              it 'should not push the message' do
                MicroQ.should_not_receive(:push)

                expect {
                  call
                }.to raise_error(Exception, 'an exception')
              end
            end
          end
        end
      end
    end
  end
end
