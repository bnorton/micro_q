module MicroQ
  module Middleware
    module Server
      class Timeout
        DEFAULT = 10 * 60

        include ::Timeout

        def call(_, message)
          time = (time = message['timeout'].to_i) > 0 ? time : DEFAULT

          timeout(time) do
            yield
          end
        end
      end
    end
  end
end
