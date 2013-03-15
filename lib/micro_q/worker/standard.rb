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
    # A more complex message: (Calls the update_data with a single parameter as a list of ids)
    # { :class => 'MyUpdater', 'method' => 'update_data', :args => [[2, 6,74, 198]]}
    #
    class Standard
      include Celluloid

      def initialize(manager)
        @manager = manager
      end

      def perform(message)
        klass = fetch_klass(message)

        method = message['method'] || 'perform'
        args = message['args']

        defer do
          MicroQ.middleware.server.call(klass, message) do
            klass.send(method, *args)
          end
        end

        @manager.work_done!(current_actor)
      end

      def fetch_klass(message)
        klass = MicroQ::Util.constantize(message['class'].to_s)

        loader = message['loader'] ||= { 'method' => 'new' }
        klass = klass.send(loader['method'], *loader['args']) if loader['method']

        klass
      end
    end
  end
end
