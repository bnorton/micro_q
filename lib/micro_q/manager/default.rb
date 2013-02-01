module MicroQ
  module Manager
    class Default
      include Celluloid

      attr_reader :queue, :workers

      def initialize
        @queue   = MicroQ::Queue::Default.new
        @workers = MicroQ::Worker::Standard.pool(:size => MicroQ.config.workers)
      end

      def start
        if (messages = queue.dequeue).any?
          messages.each do |message|
            workers.perform!(message)
          end
        end

        after(5) { start }
      end
    end
  end
end
