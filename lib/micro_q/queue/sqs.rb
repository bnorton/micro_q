module MicroQ
  module Queue
    class Sqs
      include Celluloid

      attr_accessor :messages
      attr_reader   :fetchers, :entries, :later

      def initialize
        @lock = Mutex.new

        @messages, @entries, @later = [], [], []
        @fetcher_map = {}

        build_missing_fetchers
      end

      def push(item)
        async.sync_push(item)
      end

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

      def self.shutdown!
        @shutdown = true
      end

      private

      def self.shutdown?
        @shutdown
      end

      def build_missing_fetchers
        return if self.class.shutdown?

        @fetchers = QUEUES.keys.map do |name|
          ((existing = @fetcher_map[name]) && existing.alive? && existing) ||
            MicroQ::Fetcher::Sqs.new_link(name, current_actor).tap do |fetcher|
              @fetcher_map[name] = fetcher
            end
        end
      end

      QUEUES = { :low => 1, :default => 3, :critical => 5 }
    end
  end
end
