module MicroQ
  module Middleware
    module Client
      class Statistics
        include MicroQ::Middleware::Util

        ENQUEUED = proc {|klass| klass ? "messages:#{klass}:enqueued" : 'messages:enqueued' }

        def call(message, options)
          stats(message)
          yield
        end

        private

        def stats(msg)
          stats_incr(msg, ENQUEUED, "queues:#{msg['queue']}:enqueued")
        end
      end
    end
  end
end
