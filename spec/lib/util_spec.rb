require 'spec_helper'

describe MicroQ::Util do
  describe '.constantize' do
    it 'should work form simple class names' do
      MicroQ::Util.constantize('MicroQ').should == MicroQ
    end

    it 'should work for complex class names' do
      MicroQ::Util.constantize('MicroQ::Util').should == MicroQ::Util
    end

    it 'should work for "root" complex class names' do
      MicroQ::Util.constantize('::MicroQ::Util').should == MicroQ::Util
    end
  end
end
