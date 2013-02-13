module MicroQ
  def self.redis
    redis_connection.with do |r|
      yield r
    end
  end

  def self.redis_connection
    @@redis_connection ||= begin
      ::ConnectionPool.new(config.redis_pool) do
        ::Redis.new(config.redis)
      end
    end
  end
end
