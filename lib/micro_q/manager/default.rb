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

      # Invoke this when the Queue or Worker pool dies
      exit_handler :reinitialize

      attr_reader :queue, :workers

      def start
        count = workers.idle_size

        if (messages = queue.dequeue(count)).any?
          messages.each do |message|
            workers.perform!(message)
          end
        end

        after(2) { start }
      end

      ##
      # Handle init/death of the Queue or the Worker pool
      #
      def reinitialize(*)
        unless @queue && @queue.alive?
          @queue = MicroQ.config.queue.new_link
        end

        unless @workers && @workers.alive?
          @workers = MicroQ.config.worker.pool_link(:size => MicroQ.config.workers)
        end
      end

      alias initialize reinitialize
    end
  end
end
