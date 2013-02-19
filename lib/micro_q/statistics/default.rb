module MicroQ
  module Statistics
    class Default < Base
      def initialize
        @increment = Hash.new { 0 }
        @increment_mutex = Mutex.new
      end

      def incr(*keys)
        @increment_mutex.synchronize do
          keys.flatten.each do |key|
            @increment[key.to_s] += 1
          end
        end
      end
    end
  end
end
