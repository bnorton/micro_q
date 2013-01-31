require 'spec_helper'

describe MicroQ::Queue::Default do
  describe '#entries' do
    it 'should be empty' do
      subject.entries.should == []
    end
  end

  describe '#later' do
    it 'should be empty' do
      subject.later.should == []
    end
  end
end
