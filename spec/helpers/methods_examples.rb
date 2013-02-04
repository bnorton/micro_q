shared_examples_for "a_worker" do |method|
  describe "additions (#{method})" do
    it 'should add an async proxy' do
      subject.respond_to?(:async).should == true
    end

    it 'should proxy to the object' do
      subject.async.respond_to?(method).should == true
    end

    describe 'before first calling the _async method' do
      it 'should not respond to the _async method' do
        subject.respond_to?(method).should == true
        subject.respond_to?("#{method}_async").should == false
      end
    end

    describe 'after first call' do
      before do
        subject.send("#{method}_async")
      end

      it "should add a _async method" do
        subject.respond_to?(method).should == true
        subject.respond_to?("#{method}_async").should == true
      end
    end
  end

  describe 'errors' do
    describe 'when calling a missing _async method' do
      it 'should fail' do
        expect {
          subject.send("some_method_async")
        }.to raise_error
      end

      it 'should raise an undefined method error (without the _async)' do
        ex = (begin; subject.send("some_method_async"); rescue => e; e end)

        ex.message.should match(/undefined method \`some_method_async\' for/)
      end
    end
  end
end
