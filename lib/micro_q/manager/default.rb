module MicroQ
  module Manager
    ##
    # The default manager implementation.
    # Wrapper for a Queue and a pool of Workers. At each time slice
    # after start! was called, try to dequeue messages from the queue.
    # Perform each message on the worker pool.
    #
    # The pool of workers (more info):
    #   https://github.com/celluloid/celluloid/wiki/Pools
    #
    # The pool manages asynchronously assigning messages to available
    # workers, handles exceptions by restarting the dead actors and
    # is generally a beautiful abstraction on top of a group of linked
    # actors/threads.
    #
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
