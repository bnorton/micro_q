require 'spec_helper'

describe MicroQ::Config do
  [[:a_key, 'abc123'], [:key, 'the-value']].each do |(method, value)|
    describe "##{method}" do
      before do
        subject.send("#{method}=", value)
      end

      it 'should access the given value (:sym)' do
        subject[method].should == value
      end

      it 'should access the given value (str)' do
        subject[method.to_s].should == value
      end

      it "should have the value at ##{method}" do
        subject.send(method).should == value
      end
    end
  end

  describe 'defaults' do
    subject { MicroQ.config }

    it 'should have 5 workers' do
      subject.workers.should == 5
    end

    it 'should have a 5 second interval' do
      subject.interval.should == 5
    end

    it 'should have a 120 second timeout' do
      subject.timeout.should == 120
    end

    it 'should have middleware chain' do
      subject.middleware.class.should == MicroQ::Middleware::Chain
    end

    it 'should not have a logfile' do
      subject.logfile.should == nil
    end

    it 'should have a redis pool config' do
      subject.redis_pool.should == { :size => 15, :timeout => 1 }
    end

    it 'should have a redis config' do
      subject.redis.should == { :host => 'localhost', :port => 6379 }
    end

    it 'should have the default queue' do
      subject.manager.should == MicroQ::Manager::Default
    end

    it 'should have the default queue' do
      subject.queue.should == MicroQ::Queue::Default
    end

    it 'should have the standard worker' do
      subject.worker.should == MicroQ::Worker::Standard
    end

    it 'should have the default statistics' do
      subject.statistics.should == MicroQ::Statistics::Default
    end
  end
end
