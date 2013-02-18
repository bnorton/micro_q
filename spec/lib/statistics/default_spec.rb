require 'spec_helper'

describe MicroQ::Statistics::Default do
  describe '.stats' do
    it 'should yield a default statistics obj' do
      MicroQ::Statistics::Default.stats {|stats| stats.class.should == MicroQ::Statistics::Default }
    end

    it 'should memoize the instance' do
      items = []
      2.times { MicroQ::Statistics::Default.stats {|stats| items << stats.object_id } }

      items.uniq.length.should == 1
    end
  end

  describe '.instance' do
    it 'should be the statistics obj' do
      MicroQ::Statistics::Default.instance.class.should == MicroQ::Statistics::Default
    end

    it 'should memoize the instance' do
      2.times.collect { MicroQ::Statistics::Default.instance }.uniq.length.should == 1
    end
  end

  describe '#increment' do
    it 'should be a hash' do
      subject.increment.should == {}
    end
  end
  describe '#incr' do
    before do
      subject.incr("key_name")
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
        3.times { subject.incr("other") }
      end

      it 'should increment the key' do
        subject.increment.should == {
          'key_name' => 1,
          'other' => 4
        }
      end
    end
  end
end
