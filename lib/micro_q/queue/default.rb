module MicroQ
  module Queue
    class Default
      include Celluloid

      attr_reader :entries, :later

      def initialize
        @entries = []
        @later   = []
      end

      def push(item, options = {})
        item = item.dup

        if (time = options['when'])
          @later.push(
            'when' => time,
            'worker' => item
          )
        else
          @entries.push(item)
        end
      end

      def dequeue
        [].tap do |items|
          entries.each do |entry|
            items << entry
          end if entries.any?

          items.each {|i| entries.delete(i) }

          available = later.select {|entry| entry['when'] < Time.now.to_f }

          if available.any?
            available.each do |entry|
              items << entry['worker']
            end

            available.each {|a| later.delete(a) }
          end
        end
      end
    end
  end
end
