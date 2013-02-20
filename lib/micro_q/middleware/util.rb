module MicroQ
  module Middleware
    module Util
      def stats_incr(msg, generator, *keys)
        statistics do |stats|
          stats.incr(
            generator.call,
            generator.call(msg['class']),
            *keys.flatten
          )
        end
      end

      def statistics
        MicroQ::Statistics::Default.stats do |stats|
          yield stats
        end
      end
    end
  end
end
