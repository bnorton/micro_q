shared_examples 'Queue#sync_push' do
  it 'should add to the entries' do
    subject.sync_push(item)

    subject.entries.should include(item)
  end

  it 'should stringify the class' do
    subject.sync_push(:class => MyWorker)

    subject.entries.should include('class' => 'MyWorker')
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
      MicroQ.middleware.client.should_receive(:call) do |payload, opts|
        payload['class'].should == 'MyWorker'
        payload['args'].should == [4]

        opts['when'].should == 'now'
      end

      subject.sync_push(item, 'when' => 'now')
    end
  end
end
