module MicroQ
  module Middleware
    module Server
      class Statistics
        def call(worker, message)
          yield
        end
      end
    end
  end
end
