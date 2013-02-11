module MicroQ
  module Methods
    module ActionMailer
      def async
        MicroQ::Proxy::ActionMailer.new(
          :class => MicroQ::Wrapper::ActionMailer,
          :base => self
        )
      end
    end
  end
end

MicroQ::Util.safe_require 'action_mailer'
if defined?(ActionMailer::Base)
  ActionMailer::Base.send(:extend, MicroQ::Methods::ActionMailer)
end
