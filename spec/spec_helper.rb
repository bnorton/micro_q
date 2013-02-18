require 'micro_q'
require 'time'
require 'timecop'
require 'mock_redis'

[:methods, :queues].
  each {|path| require "helpers/#{path}_examples" }

Celluloid.logger = nil

# Don't require an actual Redis instance for testing
silence_warnings do
  Redis = MockRedis
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true

  config.order = 'default'

  config.before :each do
    MicroQ.send :clear
    MicroQ.redis {|r| r.flushdb }
  end

  config.before :each, :active_record => true do
    require 'active_record'
    require 'sqlite3' # https://github.com/luislavena/sqlite3-ruby

    db_name = ENV['TEST_DATABASE'] || 'micro_q-test.db'

    (@_db = SQLite3::Database.new(db_name)).
    execute(<<-SQL)
      create table if not exists repositories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name varchar(255)
      );
    SQL

    # ** Transactional fixtures. BEGIN **
    @_db.transaction

    ActiveRecord::Base.establish_connection(
      :adapter => 'sqlite3',
      :database =>  db_name
    )
  end

  config.after :each, :active_record => true do
    # ** Transactional fixtures. END **
    @_db.rollback
  end

  config.before :each, :middleware => true do
    class WorkerClass; end

    @worker = WorkerClass.new
    @payload = { 'class' => 'WorkerClass', 'args' => [1, 2], 'queue' => 'a-queue'}
  end
end

def safe(method, *args)
  send(method, *args)
rescue Exception
  nil
end
