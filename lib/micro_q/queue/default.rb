module MicroQ
  module Queue
    class Default
      include Celluloid

      attr_reader :entries, :later

      def initialize
        @entries = []
        @later   = []
      end
    end
  end
end
