require 'spec_helper'

describe MicroQ do
  describe '.configure' do
    it 'should be the config' do
      MicroQ.configure {|config| config.class.should == MicroQ::Config }
    end

    it "should cache the value" do
      configs = []

      2.times { MicroQ.configure {|c| configs << c } }

      configs[0].should == configs[1]
    end
  end

  describe '.config' do
    it 'should be the config' do
      MicroQ.config.class.should == MicroQ::Config
    end
  end

  describe '.middleware' do
    it 'should alias the middleware on the config' do
      MicroQ.middleware.should == MicroQ.config.middleware
    end
  end

  describe '.start' do
    def start
      MicroQ.start
    end

    before do
      @manager = mock(MicroQ::Manager::Default, :start! => nil)
      MicroQ::Manager::Default.stub(:new).and_return(@manager)
    end

    it 'should create a queue' do
      MicroQ::Manager::Default.should_receive(:new).and_return(@manager)

      start
    end

    it 'should cache the queue' do
      MicroQ::Manager::Default.should_receive(:new).once.and_return(@manager)

      3.times { start }
    end

    it 'should asynchronously start the manager (once)' do
      @manager.should_receive(:start!).once

      start
    end
  end

  describe '.push' do
    let(:args) { [{ :class => 'WorkerClass' }, { :option => 'value' }] }

    def push
      MicroQ.push(*args)
    end

    before do
      @async = mock(Celluloid::AsyncProxy)
      @manager = mock(MicroQ::Manager::Default, :start! => nil, :queue => mock("Queue", :async => @async))
      MicroQ::Manager::Default.stub(:new).and_return(@manager)

      MicroQ.start
    end

    it 'should delegate to the manager\'s queue' do
      @async.should_receive(:push).with(*args)

      push
    end
  end
end
