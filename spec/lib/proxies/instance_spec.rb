require 'spec_helper'

describe MicroQ::Proxy::Instance do
  class MyModel
    def process
    end
  end

  let(:options) { { :class => MyModel } }

  subject { MicroQ::Proxy::Instance.new(options) }

  it 'should be a base proxy' do
    subject.class.ancestors.should include(MicroQ::Proxy::Base)
  end

  describe '#respond_to?' do
    it 'should be false' do
      subject.respond_to?(:not_a_method).should == false
    end

    describe 'for a method the instance responds to' do
      it 'should be true' do
        subject.respond_to?(:process).should == true
      end
    end

    describe 'for a method the proxy responds to and a class instance doesn\'t' do
      before do
        @method = (subject.methods - options[:class].new.methods).first
      end

      it 'should be true' do
        options[:class].new.respond_to?(@method).should == false
        subject.klass.new.respond_to?(@method).should == false

        subject.respond_to?(@method).should == true
      end
    end
  end
end
