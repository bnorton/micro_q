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

          unless message['retried']['count'] > retry_count(message)
            MicroQ.push(message, message['retried'])
          end

          raise e
        end

        private

        def retry_count(msg)
          [Fixnum, String].include?(msg['retry'].class) ? msg['retry'].to_i : 25
        end

        def retried!(msg)
          msg['retried'] ||= { 'count' => 0 }

          msg['retried']['at']    = Time.now
          msg['retried']['when']  = next_retry(msg['retried'])
          msg['retried']['count'] += 1
        end

        ## On retry:
        #    0-3   random interval up to 12 seconds
        #    4-13  retry after an exponential amount of time
        #          otherwise retry after 8 hours
        def next_retry(retried)
          count = retried['count']

          (Time.now + case count
            when 0..3 then rand(2..12)
            when 4..13 then (count** 4)
            else 8*60*60
          end).to_f
        end

        def stats(msg)
          stats_incr(msg, RETRY, "queues:#{msg['queue']}:retry")
        end
      end
    end
  end
end
