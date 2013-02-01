module MicroQ
  class Config
    def initialize
      @data = {
        'workers' => 3,
        'timeout' => 120,
        'interval' => 5,
        'middleware' => MicroQ::Middleware::Chain.new
      }
    end

    def []=(key, value)
      @data[key.to_s] = value
    end

    def [](key)
      @data[key.to_s]
    end

    def method_missing(method, *args)
      case method
        when /(.+)=$/ then @data[$1] = args.first
        else @data[method.to_s]
      end
    end
  end
end
