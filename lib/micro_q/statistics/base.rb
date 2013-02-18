module MicroQ
  module Statistics
    class Base
      attr_reader :increment

      def self.stats
        yield instance
      end

      def self.instance
        @instance ||= new
      end
    end
  end
end
