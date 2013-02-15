shared_examples_for 'Queue#sync_push' do
  it 'should add to the entries' do
    subject.sync_push(item)

    subject.entries.should include(item)
  end

  it 'should duplicate the item' do
    subject.sync_push(item)

    before = item.dup
    subject.entries.should include(before)

    item[:key] = 'new-value'
    subject.entries.should_not include(item)
    subject.entries.should include(before)
  end

  describe 'client middleware' do
    it 'should process the middleware chain' do
      MicroQ.middleware.client.should_receive(:call) do |w, payload|
        w.should == 'MyWorker'

        payload['class'].should == 'MyWorker'
        payload['args'].should == [4]
      end

      subject.sync_push(item)
    end
  end
end
