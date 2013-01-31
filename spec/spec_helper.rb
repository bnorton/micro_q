require 'micro_q'
require 'time'
require 'timecop'
require 'celluloid'

Celluloid.logger = nil

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true

  config.order = 'random'

  config.before :each do
    MicroQ.send :clear
  end

  config.before :each, :middleware => true do
    class WorkerClass; end

    @worker = WorkerClass.new
    @payload = { 'class' => 'WorkerClass', 'args' => [1, 2]}
  end
end

def safe(method, *args)
  send(method, *args)
rescue Exception
  nil
end
