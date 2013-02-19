require 'spec_helper'

describe MicroQ::Statistics::Redis do
  describe '.stats' do
    it 'should yield a default statistics obj' do
      MicroQ::Statistics::Redis.stats {|stats| stats.class.should == MicroQ::Statistics::Redis }
    end

    it 'should memoize the instance' do
      items = []
      2.times { MicroQ::Statistics::Redis.stats {|stats| items << stats.object_id } }

      items.uniq.length.should == 1
    end
  end

  describe '.instance' do
    it 'should be the statistics obj' do
      MicroQ::Statistics::Redis.instance.class.should == MicroQ::Statistics::Redis
    end

    it 'should memoize the instance' do
      2.times.collect { MicroQ::Statistics::Redis.instance }.uniq.length.should == 1
    end
  end

  describe '#increment' do
    it 'should be a hash' do
      subject.increment.should == {}
    end
  end

  describe '#incr' do
    before do
      subject.incr('key_name')
      subject.incr(:other)
    end

    it 'should add/increment the key' do
      subject.increment.should == {
        'key_name' => 1,
        'other' => 1
      }
    end

    describe 'when called again' do
      before do
        3.times { subject.incr('other') }
      end

      it 'should increment the key' do
        subject.increment.should == {
          'key_name' => 1,
          'other' => 4
        }
      end
    end

    describe 'when given may keys' do
      before do
        2.times { subject.incr('other', 'another-key') }
      end

      it 'should increment each key' do
        subject.increment.should == {
          'key_name' => 1,
          'other' => 3,
          'another-key' => 2,
        }
      end
    end
  end
end
