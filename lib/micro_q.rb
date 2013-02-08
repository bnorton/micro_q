require 'celluloid'
require 'micro_q/util'
require 'micro_q/config'
require 'micro_q/manager'

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

  def self.start
    manager
  end

  def self.push(*args)
    manager.queue.push(*args)
  end

  private

  def self.manager
    @manager ||= begin
      Manager::Default.new.tap do |manager|
        manager.start!
      end
    end
  end

  def self.clear
    @config = @manager = nil
  end
end

require 'micro_q/middleware'
require 'micro_q/methods'
require 'micro_q/proxies'
require 'micro_q/worker'
require 'micro_q/queue'
