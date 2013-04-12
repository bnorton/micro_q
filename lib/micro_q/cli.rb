require 'slop'
require 'micro_q'

module MicroQ
  class CLI
    def self.run
      @cli ||= new
      @cli.parse
      @cli.verify!
      @cli.setup
    end

    def parse
      opts = Slop.parse do
        banner 'Usage: microq [options]'

        on 'h', 'This menu'
        on 'help', 'This menu'
        on 't=', 'The queue type to process [redis, sqs]'
        on 'type=', 'The queue type to process [redis, sqs]'
        on 'r=', 'The path to the rails application'
        on 'require=', 'The path to the rails application'
        on 'w=', 'The number of worker threads'
        on 'workers=', 'The number of worker threads'
      end

      (puts usage; exit) if opts[:help] || opts[:h]

      @workers = opts[:workers] || opts[:w]
      @require = opts[:require] || opts[:r] || 'config/environment.rb'
      @mode = (opts[:type] || opts[:t] || 'sqs'.tap { puts 'Defaulting to sqs type' }).downcase
    end

    def verify!
      unless File.exist?(@require) || File.exist?("#{@require}/config/application.rb")
        puts 'Typically the -r option is simply the base path of the application'
        puts 'This could be `pwd` or something special in production...'
        puts "We tried both File.exist?(opts[:require]) and File.exist?(opts[:require] + 'config/application.rb')"
        raise "MicroQ requires a valid rails application path via the -r option\n"
      end
    end

    def setup
      puts 'Requiring rails application...'

      require 'rails'

      if File.directory?(@require)
        require File.expand_path("#{@require}/config/environment.rb")
      else
        require @require
      end

      Rails.application.eager_load!

      aws_keys = MicroQ.config.aws.try(:keys) || []

      queue = if @mode == 'sqs'
        raise 'SQS mode requires an aws :key and :secret see https://github.com/bnorton/micro_q/wiki/Named-Queues' unless aws_keys.include?(:key) && aws_keys.include?(:secret)

        MicroQ::Queue::Sqs
      elsif @mode == 'redis'
       puts 'Using redis config' + MicroQ.config.redis.map {|(k,v)| "#{k}=#{v}" }.join(' ')

        MicroQ::Queue::Redis
      else
        raise 'Only Redis and SQS mode are supported via the command line.'
      end

      MicroQ.configure do |config|
        config.queue = queue # set workers after assigning the queue since this sets workers=0 internally for the sqs queue
        config.workers = @workers.to_i if @workers
        config['worker_mode?'] = true
      end

      puts "Running micro_q in #{@mode.upcase} mode with #{MicroQ.config.workers} workers..."
      puts 'ctl+c to shutdown...'
      MicroQ.start

      sleep
    rescue Interrupt
      puts 'Exiting via interrupt'
      exit(1)
    end

    def usage
      <<-USAGE
  Run microq with messages enqueued to and dequeued from SQS or Redis.
  Usage: microq [options]
    -h, --help              This menu.
    -t, --type [redis, sqs] The type of queue being utilized (either Redis or SQS)
    -r, --require           The path the rails app's config/environment.rb file.
    -w, --workers           The number of workers for this process.
      USAGE
    end
  end
end
