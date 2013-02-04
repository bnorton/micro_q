module MicroQ
  module Middleware
    module Server
      class Connection
        def call(*)
          yield
        ensure
          if defined?(ActiveRecord::Base)
            ActiveRecord::Base.clear_active_connections!
          end
        end
      end
    end
  end
end
