module MicroQ
  module Queue
    ##
    # The default queue implementation.
    # Handles messages that should be run immediately as well as messages that
    # should be run at some specified time in the future.
    #
    # When shutting down, if the MicroQ.config.queue_file is defined and accessible,
    # the messages in the queue will be written for persistence.
    #
    # Usage:
    #
    # item = { 'class' => 'MyWorker', 'args' => [user.id] }
    #
    # queue = MicroQ::Queue::Default.new
    # queue.push(item)       # asynchronous push (preferred)
    # queue.sync_push(item)  # synchronous push
    #
    # queue.entries
    # #=> [{'class' => 'MyWorker', 'args' => [32]}]
    #
    # queue.push(item, :when => 15.minutes.from_now)
    #
    # queue.later
    # [{'when' => 1359703628.38, 'worker' => {'class' => 'MyWorker', 'args' => 32}}]
    #
    class Default
      include Celluloid

      attr_reader :entries, :later

      def initialize
        @entries = []
        @later   = []

        load_queues
      end

      ##
      # Asynchronously push a message item to the queue.
      #
      def push(item, options={})
        async.sync_push(item, options)
      end

      ##
      # Asynchronously push a message item to the queue.
      # Either push it to the immediate portion of the queue or store it for after when
      # it should be run with the :when option.
      #
      # Options:
      #   when: The time/timestamp after which to run the message.
      #
      def sync_push(item, options={})
        item, options = MicroQ::Util.stringify(item, options)
        item['class'] = item['class'].to_s

        MicroQ.middleware.client.call(item, options) do
          if (time = options['when'])
            @later.push(
              'when' => time.to_f,
              'worker' => item
            )
          else
            @entries.push(item)
          end
        end
      end

      ##
      # Remove and return all available messages.
      # Optionally give a limit and return only limit number of messages
      #
      def dequeue(limit = 30)
        return [] if limit == 0

        opts = { :i => 0, :limit => limit}
        [].tap do |items|
          dequeue_entries!(items, opts)
          dequeue_later!(items, opts)
        end
      end

      ##
      # Stop the queue and store items for later
      #
      def stop
        File.open(queue_file, 'w+') do |f|
          f.write(YAML.dump(entries))
        end if queue_file?

        terminate
      end

      private

      def dequeue_entries!(items, options)
        entries.each do |entry|
          items << entry unless (options[:i] += 1) > options[:limit]
        end if entries.any?

        items.each {|i| entries.delete(i) }
      end

      def dequeue_later!(items, options)
        available = later.select {|entry| entry['when'] < Time.now.to_f }

        if available.any?
          available.each do |entry|
            items << entry['worker'] unless (options[:i] += 1) > options[:limit]
          end

          available.each {|a| later.delete(a) }
        end
      end

      ##
      # Parse the entries back into the queue from the filesystem
      #
      def load_queues
        if queue_file? && File.exists?(queue_file)
          @entries = YAML.load(File.new(queue_file).read)

          File.unlink(queue_file)
        end
      end

      def queue_file
        @queue_file ||= MicroQ.config.queue_file
      end

      def queue_file?
        queue_file && File.exists?(File.dirname(queue_file))
      end
    end
  end
end
