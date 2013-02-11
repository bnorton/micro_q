module MicroQ
  module Proxy
    class ActionMailer < Base
      def method_missing(meth, *args)
        @args = [@options.delete(:base).to_s, meth.to_s, *args]

        defaults = [{
          :class => MicroQ::Wrapper::ActionMailer,
          :method => 'perform',
          :args => @args
        }.merge(@options)]

        defaults << { :when => at } if at

        MicroQ.push(*defaults)
      end
    end
  end
end
