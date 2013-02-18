module MicroQ
  module Middleware
    module Util
      def statistics
        MicroQ::Statistics::Default.stats do |stats|
          yield stats
        end
      end
    end
  end
end
