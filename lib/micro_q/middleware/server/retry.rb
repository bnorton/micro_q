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
        def call(worker, message)
          yield
        rescue Exception => e
          raise e unless message['retry']

          message['retried'] ||= { 'count' => 0 }

          message['retried']['count'] += 1
          message['retried']['at']    = Time.now
          message['retried']['when']  = (Time.now + 15).to_f

          MicroQ.push(message, message['retried'])

          raise e
        end
      end
    end
  end
end
