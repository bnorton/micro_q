module MicroQ
  module Queue
    ##
    # The default queue implementation.
    # Handles messages that should be run immediately as well as messages that
    # should be run at some specified time in the future.
    #
    # Usage:
    #
    # item = { 'class' => 'MyWorker', 'args' => [user.id] }
    #
    # queue = MicroQ::Queue::Default.new
    # queue.push(item)       # synchronous push
    # queue.async.push(item) # asynchronous push (preferred)
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
      end

      ##
      # Push a message item to the queue.
      # Either push it to the immediate portion of the queue or store it for after when
      # it should be run with the 'when' option.
      #
      # Options:
      #   when: The time/timestamp after which to run the message.
      #
      def push(item, options={})
        item, options = before_push(item, options)

        if (time = options['when'])
          @later.push(
            'when' => time.to_f,
            'worker' => item
          )
        else
          @entries.push(item)
        end
      end

      ##
      # Remove and return all available messages.
      #
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

      private

      ##
      # Duplicate the given items and stringify the keys.
      #
      def before_push(args, options)
        [MicroQ::Util.stringify_keys(args),
         MicroQ::Util.stringify_keys(options)
        ]
      end
    end
  end
end
