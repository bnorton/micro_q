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

  describe '#push' do
    let(:item) { { 'class' => 'MyWorker', 'args' => [] } }

    it 'should add to the entries' do
      subject.push(item)

      subject.entries.should include(item)
    end

    it 'should duplicate the item' do
      item.should_receive(:dup)

      subject.push(item)
    end

    describe 'when given the "when" key' do
      let(:worker) { [item, { 'when' => (Time.now + 100).to_i }] }

      it 'should add to the later' do
        subject.push(*worker)

        subject.later.should include(
          'when' => (Time.now + 100).to_i,
          'worker' => item
        )
      end

      it 'should not be in the entries' do
        subject.push(*worker)

        subject.entries.should == []
      end
    end
  end

  describe '#dequeue' do
    let(:item) { { 'class' => 'MyWorker', 'args' => [] } }

    class MyWorker
      def perform(*)
      end
    end

    describe 'when there are entries' do
      before do
        subject.push(item)
      end

      it 'should return the item' do
        subject.dequeue.should == [item]
      end

      it 'should remove the item from the list' do
        subject.dequeue

        subject.entries.should_not include(item)
      end
    end

    describe 'when there are items to be processed later' do
      before do
        subject.push(item, 'when' => (Time.now + 5).to_i)
      end

      it 'should not return the item' do
        subject.dequeue.should == []
      end

      it 'should not remove the item' do
        subject.dequeue

        subject.later.should == ['when' => (Time.now + 5).to_i, 'worker' => item]
      end

      describe 'when the item is in the past' do
        before do
          subject.later.first['when'] = (Time.now - 2).to_i
        end

        it 'should return the item' do
          subject.dequeue.should == [item]
        end

        it 'should remove the item from the list' do
          subject.dequeue

          subject.later.should == []
        end
      end
    end

    describe 'when there are many items' do
      let(:later_item) { [item.dup.tap {|it| it['args'] = %w(special) }, 'when' => (Time.now + 5).to_i] }
      let(:items) do
        5.times.collect {|i|
          item.dup.tap {|it| it['args'] = [i]}
        }
      end

      before do
        items.first(4).each {|item| subject.push(item) }
        subject.push(items.last, 'when' => (Time.now - 2).to_i)

        subject.push(*later_item)
      end

      it 'should return all the available items' do
        subject.dequeue.sort {|x, y| x['args'][0] <=> y['args'][0] }.should == items
      end

      it 'should remove the items' do
        subject.dequeue

        subject.entries.should == []
        subject.later.should == [later_item[1].merge('worker' => later_item[0])]
      end
    end
  end
end
