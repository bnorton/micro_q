module MicroQ
  module Middleware
    module Server
      ##
      # Capture, re-raise and potentially push a modified message
      # back onto the queue. We add metadata about the retry into the
      # 'retried' key to track the attempts.
      #
      # count: The number of retires thus far
      # at:    When the last retry occurred
      # when:  The time at which the message will be retried again
      #
      class Retry
        include MicroQ::Middleware::Util

        RETRY = proc {|klass| klass ? "messages:#{klass}:retry" : 'messages:retry' }

        def call(worker, message)
          yield
        rescue Exception => e
          raise e unless message['retry']

          retried!(message)
          stats(message)

          MicroQ.push(message, message['retried'])

          raise e
        end

        private

        def retried!(msg)
          msg['retried'] ||= { 'count' => 0 }

          msg['retried']['count'] += 1
          msg['retried']['at']    = Time.now
          msg['retried']['when']  = (Time.now + 15).to_f
        end

        def stats(msg)
          statistics do |stats|
            stats.incr(
              RETRY.call,
              RETRY.call(msg['class']),
              "queues:#{msg['queue']}:retry"
            )
          end
        end
      end
    end
  end
end
