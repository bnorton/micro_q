module MicroQ
  module Middleware
    module Server
      class Retry
        def call(worker, payload)
          yield
        rescue Exception => e
          raise e unless payload['retry']

          payload['retried'] ||= { 'count' => 0 }

          payload['retried']['count'] += 1
          payload['retried']['at']    = Time.now
          payload['retried']['when']  = (Time.now + 15).to_f

          MicroQ.push(payload, payload['retried'])

          raise
        end
      end
    end
  end
end
