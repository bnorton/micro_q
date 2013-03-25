require 'timeout'
require 'celluloid'
require 'connection_pool'

require 'micro_q/util'
require 'micro_q/config'
require 'micro_q/manager'

Celluloid.logger = nil

module MicroQ
  def self.config
    @config ||= Config.new
  end

  def self.configure
    yield config
  end

  def self.middleware
    config.middleware
  end

  def self.stats(&block)
    config.statistics.stats(&block)
  end

  def self.start
    manager
  end

  def self.push(*args)
    manager.queue.push(*args)
  end

  private

  def self.manager
    @manager ||= begin
      config.manager.new.tap do |manager|
        manager.start!
      end
    end
  end

  def self.clear
    @config = @manager = nil
  end
end

require 'micro_q/middleware'
require 'micro_q/proxies'
require 'micro_q/dsl'
require 'micro_q/worker'
require 'micro_q/queue'

require 'micro_q/redis'

require 'micro_q/wrappers/action_mailer'

# add Class and Instance methods first then
# override with additional extensions

require 'micro_q/methods/class'
require 'micro_q/methods/instance'
require 'micro_q/methods/action_mailer'

require 'micro_q/statistics/base'
require 'micro_q/statistics/default'
require 'micro_q/statistics/redis'

# There is a better way coming soon 2/18/13
at_exit do
  MicroQ::Manager::Default.shutdown!
end
