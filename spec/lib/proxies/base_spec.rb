require 'spec_helper'

describe MicroQ::Proxy::Base do
  class MyModel
    def self.seed
    end

    def process
    end
  end

  let(:options) { { :class => MyModel } }

  subject { MicroQ::Proxy::Base.new(options) }

  describe '.new' do
    describe 'when given the :at key' do
      before do
        Timecop.freeze

        options[:at] = (Time.now + 60)
      end

      it 'should store the value' do
        subject.at.should == (Time.now + 60).to_i
      end
    end

    describe 'when given the :after key' do
      before do
        Timecop.freeze

        options[:after] = 60
      end

      it 'should store the at time' do
        subject.at.should == (Time.now + 60).to_i
      end
    end
  end

  describe 'valid?' do
    it { should be_valid }
    it { subject.klass.should == MyModel }

    describe 'class' do
      it 'should require a class' do
        options[:class] = nil

        should_not be_valid
      end

      it 'should require a constant' do
        options[:class] = 'InvalidClass'

        should_not be_valid
      end

      describe '#errors' do
        [nil, 'InvalidClass'].each do |type|
          it "should have an error for #{type.inspect}" do
            options[:class] = type

            subject.errors.should include('Proxies require a valid class')
          end
        end
      end
    end
  end

  describe '#respond_to?' do
    it 'should be false' do
      subject.respond_to?(:not_a_method).should == false
    end

    describe 'for a method the class responds to' do
      it 'should be true' do
        subject.respond_to?(:seed).should == true
      end
    end

    describe 'for a method the proxy responds to and the class doesn\'t' do
      before do
        @method = (subject.methods - options[:class].methods).first
      end

      it 'should be true' do
        options[:class].respond_to?(@method).should == false
        subject.klass.respond_to?(@method).should == false

        subject.respond_to?(@method).should == true
      end
    end
  end

  describe '#method' do
    it 'should store the method' do
      subject.some_method

      subject.method.should == 'some_method'
    end
  end

  describe '#args' do
    let(:args) { [1 ,2, 'value'] }

    it 'should store given arguments' do
      subject.some_method(*args)

      subject.args.should == [1 ,2, 'value']
    end
  end

  describe 'method invocations' do
    let(:method) { -> { subject.some_method(1, 2) } }

    it 'should push the message' do
      MicroQ.should_receive(:push)

      method.call
    end

    it 'should have the class' do
      MicroQ.should_receive(:push).with(hash_including(:class => MyModel))

      method.call
    end

    it 'should have the method' do
      MicroQ.should_receive(:push).with(hash_including(:method => 'some_method'))

      method.call
    end

    it 'should have the args' do
      MicroQ.should_receive(:push).with(hash_including(:args => [1, 2]))

      method.call
    end

    describe 'when given options' do
      before do
        options[:loader] = {:method => 'find', :args => [456]}
        options[:foo] = 'bar'
      end

      it 'should have the random key' do
        MicroQ.should_receive(:push).with(hash_including(:foo => 'bar'))

        method.call
      end

      it 'should have the loader' do
        MicroQ.should_receive(:push).with(hash_including(:loader => {:method => 'find', :args => [456]}))

        method.call
      end
    end

    describe 'when performing at a specific time' do
      before do
        options[:at] = Time.now + 60
      end

      it 'should push with the right \'when\' key' do
        MicroQ.should_receive(:push).with(anything, :when => (Time.now + 60).to_i)

        method.call
      end
    end

    describe 'when performing after a specific time' do
      before do
        options[:after] = 120
      end

      it 'should push with the right \'when\' key' do
        MicroQ.should_receive(:push).with(anything, :when => (Time.now + 120).to_i)

        method.call
      end
    end
  end
end
