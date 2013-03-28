module MicroQ
  class Config
    ##
    # Configuration accessible via:
    # 1. hash syntax   (config[:k] and config[:k] = val)
    # 2. method syntax (config.k and config.k = val)
    #
    # To change the type of worker that is used simply assign
    # a new worker class (after requiring the file).
    #
    def initialize
      @data = {
        'workers' => 5,
        'timeout' => 120,
        'interval' => 5,
        'env' => defined?(Rails) ? Rails.env : 'development',
        'middleware' => Middleware::Chain.new,
        'manager' => Manager::Default,
        'worker' => Worker::Standard,
        'queue' => Queue::Default,
        'statistics' => Statistics::Default,
        'aws' => {},
        'redis_pool' => { :size => 15, :timeout => 1 },
        'redis' => { :host => 'localhost', :port => 6379 }
      }
    end

    def []=(key, value)
      @data[key.to_s] = value
    end

    def [](key)
      @data[key.to_s]
    end

    def queue=(q)
      if q == Queue::Sqs
        require 'aws-sdk'

        @data['sqs?'] = true
        @data['workers'] = 0
      end

      @data['queue'] = q
    end

    def method_missing(method, *args)
      case method
        when /(.+)=$/ then @data[$1] = args.first
        else @data[method.to_s]
      end
    end
  end
end
