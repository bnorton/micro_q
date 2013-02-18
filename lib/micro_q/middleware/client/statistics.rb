module MicroQ
  module Middleware
    module Client
      class Statistics
        def call(message, options)
          yield
        end
      end
    end
  end
end
