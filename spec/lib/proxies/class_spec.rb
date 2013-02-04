require 'spec_helper'

describe MicroQ::Proxy::Class do
  class MyModel
    def self.configure
    end
  end
  let(:options) { { :class => MyModel } }

  subject { MicroQ::Proxy::Class.new(options) }

  it 'should be a base proxy' do
    subject.class.ancestors.should include(MicroQ::Proxy::Base)
  end
end
