module MicroQ
  module Queue
    class Redis
      include Celluloid

      QUEUES = {
        :entries => 'micro_q:queue:entries',
        :later => 'micro_q:queue:later'
      }.freeze

      def entries
        MicroQ.redis do |r|
          r.lrange(QUEUES[:entries], 0, -1)
        end.collect(&MicroQ::Util.json_parse)
      end

      def later
        MicroQ.redis do |r|
          r.zrangebyscore(QUEUES[:later], '-inf', '+inf')
        end.collect(&MicroQ::Util.json_parse)
      end

      def push(item, options = {})
        async.sync_push(item, options)
      end

      def sync_push(item, options = {})
        item, options = MicroQ::Util.stringify(item, options)

        MicroQ.middleware.client.call(item['class'], item, options) do
          json = JSON.dump(item)

          MicroQ.redis do |r|
            if (time = options['when'])
              r.zadd(QUEUES[:later], time.to_f, json)
            else
              r.lpush(QUEUES[:entries], json)
            end
          end
        end
      end

      ##
      # Remove and return up to :limit number of items from the
      # entries queue. Move any available items from the later
      # queue into the entries for future dequeue.
      #
      def dequeue(limit = 30)
        idx, items = 0, []

        fetch(limit).tap do |(e, later)|
          e.each {|item| items << item unless (idx += 1) > limit }

          MicroQ.redis do |r|
            ((e - items) + later).each {|l| r.rpush(QUEUES[:entries], l)}
          end
        end

        items.collect(&MicroQ::Util.json_parse)
      end

      private

      def fetch(limit)
        return [] unless limit > 0

        time = Time.now.to_f

        MicroQ.redis do |r|
          [r.multi {
            limit.times.collect { r.rpop(QUEUES[:entries]) }
          }.compact,
           r.multi {
             r.zrangebyscore(QUEUES[:later], '-inf', time)
             r.zremrangebyscore(QUEUES[:later], '-inf', time)
           }.first]
        end
      end
    end
  end
end
