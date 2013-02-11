shared_examples_for "a_worker" do |method|
  describe "additions (#{method})" do
    it 'should add an async proxy' do
      subject.respond_to?(:async).should == true
    end

    it 'should proxy to the object' do
      subject.async.respond_to?(method).should == true
    end
  end
end
