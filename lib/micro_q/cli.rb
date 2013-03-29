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

        on 'r=', 'The path to the rails application'
        on 'require=', 'The path to the rails application'
        on 'w=', 'The number of worker threads'
        on 'workers=', 'The number of worker threads'
      end

      @workers = opts[:workers] || opts[:w]
      @require = opts[:require] || opts[:r]
    end

    def verify!
      raise "Need a valid path to a rails application, you gave us #{@require}\n" unless /environment\.rb/ === @require || File.exist?("#{@require}/config/application.rb")
    end

    def setup
      puts 'Requiring rails...'
      require 'rails'

      puts 'Requiring rails application...'
      if File.directory?(@require)
        require File.expand_path("#{@require}/config/environment.rb")
      else
        require @require
      end

      aws_keys = MicroQ.config.aws.try(:keys) || []
      raise 'SQS mode requires an aws :key and :secret see https://github.com/bnorton/micro_q/wiki/Named-Queues' unless aws_keys.include?(:key) && aws_keys.include?(:secret)

      puts "Running micro_q in SQS mode... Hit ctl+c to stop...\n"
      MicroQ.configure do |config|
        config.workers = @workers if @workers
        config.queue = MicroQ::Queue::Sqs
        config['worker_mode?'] = true
      end

      MicroQ.start

      sleep
    rescue Interrupt
      puts 'Exiting via interrupt'
      exit(1)
    end
  end
end
