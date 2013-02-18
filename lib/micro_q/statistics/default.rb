module MicroQ
  module Statistics
    class Default
      attr_reader :increment

      def self.statistics
        yield stats
      end

      def self.stats
        @statistics ||= new
      end

      def initialize
        @increment = Hash.new { 0 }
      end

      def incr(key)
        @increment[key.to_s] += 1
      end
    end
  end
end
