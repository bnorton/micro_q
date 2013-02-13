module MicroQ
  module Queue
    class Redis
      def entries
        MicroQ.redis do |r|
          r.lrange('micro_q:queue:entries', 0, -1)
        end.collect(&json_parse)
      end

      def later
        MicroQ.redis do |r|
          r.zrangebyscore('micro_q:queue:later', '-inf', '+inf')
        end.collect(&json_parse)
      end

      def sync_push(item, options = {})
        item, options = stringify(item, options)

        MicroQ.middleware.client.call(item['class'], item, options) do
          json = JSON.dump(item)

          MicroQ.redis do |r|
            if (time = options['when'])
              r.zadd('micro_q:queue:later', time.to_f, json)
            else
              r.rpush('micro_q:queue:entries', json)
            end
          end
        end
      end

      private

      def stringify(*args)
        args.collect do |a|
          MicroQ::Util.stringify_keys(a)
        end
      end

      def json_parse
        proc {|entry| JSON.parse(entry) }
      end
    end
  end
end
