module MicroQ
  module Wrapper
    class ActionMailer
      def perform(klass, method, *args)
        email = MicroQ::Util.constantize(klass).send(method, *args)

        email.deliver if email.respond_to?(:deliver)
      end
    end
  end
end
