require 'celluloid'
require 'micro_q/util'
require 'micro_q/config'
require 'micro_q/queue'
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
    default
  end

  def self.push(*args)
    default.async.push(args.flatten)
  end

  private

  def self.clear
    @config = @default = nil
  end

  def self.default
    @default ||= Queue::Default.new
  end
end

require 'micro_q/middleware'
require 'micro_q/worker'
