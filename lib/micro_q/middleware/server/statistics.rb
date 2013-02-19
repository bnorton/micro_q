module MicroQ
  module Middleware
    module Server
      class Statistics
        include MicroQ::Middleware::Util

        PERFORMED = proc {|klass| klass ? "messages:#{klass}:performed" : 'messages:performed' }

        def call(_, message)
          stats(message)
          yield
        end

        private

        def stats(msg)
          statistics do |stats|
            stats.incr(
              PERFORMED.call,
              PERFORMED.call(msg['class']),
              "queues:#{msg['queue']}:performed"
            )
          end
        end
      end
    end
  end
end
