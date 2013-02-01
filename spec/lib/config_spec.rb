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

    it 'should have 3 workers' do
      subject.workers.should == 3
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
  end
end
