module MicroQ
  module Middleware
    module Util
      def statistics
        MicroQ::Statistics::Default.statistics do |stats|
          yield stats
        end
      end
    end
  end
end
