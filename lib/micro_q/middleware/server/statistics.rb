module MicroQ
  module Middleware
    module Server
      class Statistics
        include MicroQ::Middleware::Util

        PERFORMED = proc {|klass| klass ? "messages:#{klass}:performed" : 'messages:performed' }

        def call(_, message)
          statistics do |stats|
            stats.incr(PERFORMED.call)
            stats.incr(PERFORMED.call(message['class']))
            stats.incr("queues:#{message['queue']}:performed")
          end
          yield
        end
      end
    end
  end
end
