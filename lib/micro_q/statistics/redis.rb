module MicroQ
  module Statistics
    class Redis < Base
      INCR = 'statistics:increment'

      def increment
        MicroQ.redis do |r|
          r.hgetall(INCR)
        end.each_with_object({}) do |(k, v), hash|
          hash[k] = v.to_i
        end
      end

      def incr(*keys)
        MicroQ.redis do |r| r.pipelined {
          keys.flatten.each do |key|
            r.hincrby(INCR, key, 1)
          end
        } end
      end
    end
  end
end
