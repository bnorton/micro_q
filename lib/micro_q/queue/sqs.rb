module MicroQ
  module Queue
    class Sqs
      include Celluloid

      exit_handler :build_missing_fetchers

      attr_accessor :messages
      attr_reader   :fetchers, :entries, :later

      def initialize
        @lock = Mutex.new

        @messages, @fetchers, @entries, @later = [], [], [], []
        @fetcher_map = {}

        build_missing_fetchers
      end

      def push(*args)
        async.sync_push(*args)
      end

      def sync_push(item, options={})
        item, options = MicroQ::Util.stringify(item, options)
        item['class'] = item['class'].to_s

        MicroQ.middleware.client.call(item, options) do
          args, queue_name = [item], verify_queue(item['queue'])

          if (time = options['when'])
            args << time.to_f
          end

          @fetcher_map[queue_name].add_message(*args)
        end
      end

      def receive_messages(*items)
        @lock.synchronize do
          (@messages += items).flatten!
        end
      end

      def dequeue(limit=30)
        return [] unless limit > 0 && messages.any?

        @lock.synchronize do
          limit.times.collect do
            messages.pop
          end.compact
        end
      end

      def finished(item)
        queue_name = verify_queue(item['queue'])
        @fetcher_map[queue_name].remove_message(item)
      end

      def verify_queue(name)
        QUEUES_KEYS.include?(name.to_s) ? name.to_s : 'default'
      end

      def self.shutdown!
        @shutdown = true
      end

      private

      def self.shutdown?
        @shutdown
      end

      def build_missing_fetchers(*)
        return if self.class.shutdown?

        @fetchers = QUEUES_KEYS.map do |name|
          ((existing = @fetcher_map[name]) && existing.alive? && existing) ||
            MicroQ::Fetcher::Sqs.new_link(name, current_actor).tap do |fetcher|
              @fetcher_map[name] = fetcher
              fetcher.start! unless MicroQ.queue_only?
            end
        end
      end

      QUEUES = { 'low' => 1, 'default' => 3, 'critical' => 5 }
      QUEUES_KEYS = QUEUES.keys
    end
  end
end
