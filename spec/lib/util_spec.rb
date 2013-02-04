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

    describe 'when the name is not defined' do
      it 'should return nil' do
        MicroQ::Util.constantize('AnUndefinedClassName').should == nil
      end
    end
  end

  describe 'stringify_keys' do
    def str(thing)
      MicroQ::Util.stringify_keys(thing)
    end

    it 'should change to strings' do
      str(:key => 'value').should == {'key' => 'value'}
    end

    it 'should work for mixed keys' do
      str(:key => 'value', 4 => '2', 'string' => 'same').should == {
        'key' => 'value',
        '4' => '2',
        'string' => 'same'
      }
    end

    it 'should deep stringify' do
      str(:top => { :key => 'value', 4 => '2', 'string' => 'same' }).should == {
        'top' => {
          'key' => 'value',
          '4' => '2',
          'string' => 'same'
        }
      }
    end
  end

  describe '.safe_require' do
    def req(lib)
      MicroQ::Util.safe_require(lib)
    end

    it 'should require the file' do
      defined?(Benchmark).should == nil
      req('benchmark')

      defined?(Benchmark).should == 'constant'
    end

    describe 'when the library is not available' do
      it 'should not error' do
        expect {
          req('foo-bar-baz')
        }.not_to raise_error
      end

      it 'should be nil' do
        req('foo-bar-baz').should == nil
      end
    end
  end
end
