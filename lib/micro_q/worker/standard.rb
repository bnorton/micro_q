module MicroQ
  module Worker
    ##
    # The default worker implementation.
    # this worker can call any method on an class instance and pass
    # an arbitrary argument list. By default it calls the 'class'.constantize#'perform'
    # method. It returns the result of the method call if possible (for debugging).
    #
    # The middleware chain can stop this message from executing by not yielding
    # to the given block.
    #
    # A minimal message: (Calls the perform method with zero arguments)
    # { :class => 'MyWorker' }
    #
    # A more complex message: (Calls the update_data with a single paramater as a list of ids)
    # { :class => 'MyUpdater', 'method' => 'update_data', :args => [[2, 6,74, 198]]}
    #
    class Standard
      include Celluloid

      def perform(message)
        klass = MicroQ::Util.constantize(message['class']).new
        method = message['method'] || 'perform'
        args = message['args']

        value = nil

        MicroQ.middleware.server.call(klass, message) do
          value = klass.send(method, *args)
        end

        value
      end
    end
  end
end
