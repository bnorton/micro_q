module MicroQ
  module Methods
    ##
    # Methods that are added to the ActionMailer class
    #
    # When mailing asynchronously, the deliver method needs to be
    # called which means a custom wrapper.
    #
    module ActionMailer
      def async(options = {})
        MicroQ::Proxy::ActionMailer.new(options.merge(
          :class => MicroQ::Wrapper::ActionMailer,
          :base => self
        ))
      end
    end
  end
end

MicroQ::Util.safe_require 'action_mailer'
if defined?(ActionMailer::Base)
  ActionMailer::Base.send(:extend, MicroQ::Methods::ActionMailer)
end
