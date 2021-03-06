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

      attr_reader :queue, :workers, :busy, :current

      def start
        return if MicroQ.queue_only?

        count = workers.size

        if (messages = queue.dequeue(count)).any?
          messages.each do |message|
            work_on(message)
          end
        end

        after(2) { start }
      end

      def work_done(worker)
        message = current.delete(worker)
        queue.finished!(message) if queue.respond_to?(:finished)

        busy.delete(worker)
        workers.push(worker)
      end

      def work_on(message)
        worker = workers.pop
        busy << worker

        current[worker] = message

        worker.perform!(message)
      end

      ##
      # Handle init/death of the Queue or the Worker pool
      # When a worker dies the args are (#<Actor ...>, #<Exception>)
      #
      def reinitialize(*args)
        kill_all and return if self.class.shutdown?

        unless @queue && queue.alive?
          @queue = MicroQ.config.queue.new_link
        end

        @busy ||= []
        @workers ||= []
        @current ||= {}

        if args.any?
          message = current.delete(args.first)
          queue.finished!(message) if queue.respond_to?(:finished)
        end

        build_missing_workers
      end

      alias initialize reinitialize

      # Don't shrink the pool if the config changes
      def build_missing_workers
        return if MicroQ.queue_only?

        workers.select!(&:alive?)
        busy.select!(&:alive?)

        missing_worker_count.times do
          workers << MicroQ.config.worker.new_link(current_actor)
        end
      end

      def missing_worker_count
        [MicroQ.config.workers - (workers.size + busy.size), 0].max
      end

      def kill_all
        (workers + busy).each {|w| w.terminate if w.alive? }
      end

      def self.shutdown?
        !!@shutdown
      end

      def self.shutdown!
        @shutdown = true
      end
    end
  end
end
