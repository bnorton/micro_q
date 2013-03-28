# MicroQ

[![Build Status](https://travis-ci.org/bnorton/micro_q.png)](https://travis-ci.org/bnorton/micro_q)  
[![Code Climate](https://codeclimate.com/github/bnorton/micro_q.png)](https://codeclimate.com/github/bnorton/micro_q)

MicroQ is a per-process asynchronous background queue.

It's simple startup and intuitive interface makes it the best choice for new and legacy apps.

## Installation

Add this line to your Gemfile:

    gem 'micro_q'

    $ bundle

Or install it:

    $ gem install micro_q

## Usage

```ruby
## A typical worker class
class MyWorker
  worker :update # sets up the dsl and adds additional _async methods

  def perform
    # do some performing here
  end

  def update(options = {})
    # do some updating
   end
end
```

###Simple

```ruby
Called on the class invoked on an instance.

MyWorker.perform_async
MyWorker.update_async(:user_id => user.id)
```

###Advanced

Safely using an ActiveRecord instance via the [Custom Loader](https://github.com/bnorton/micro_q/wiki/Loaders) API 
```ruby
# config/initializers/micro_q
require 'micro_q/methods/active_record'

# app/models/user.rb
class User < Activerecord::Base
  def update_social_data
    # Send HTTP requests to Facebook, Twitter, etc
  end
end

# app/controllers/users_controller.rb
def update
  user = account.users.find(params[:id])
  user.async.update_social_data
end
```

##Queues
By default the queue is an in-memory queue meaning that messages are shared per-process
and any unprocessed messages are saved to a file when shutdown occurs.

The **Redis queue** requires some configuration in your gemfile to keep the runtime dependencies to a minimum
```ruby
# Gemfile
gem 'redis'
gem 'micro_q'

# config/initializers/micro_q.rb
require 'redis'
require 'micro_q'

# when MicroQ starts simply use the redis queue
MicroQ.configure do |config|
  config.queue = MicroQ::Queue::Redis
end
```

The **Amazon SQS (coming soon) queue** require some extra configuration in your gemfile.
```ruby
# Gemfile
gem 'aws-sdk'
gem 'micro_q'

# config/initializers/micro_q.rb
require 'aws-sdk'
require 'micro_q'

# when MicroQ starts simply use the sqs queue
# this will take care of all other switchover for the system
MicroQ.configure do |config|
  config.queue = MicroQ::Queue::Sqs
  config.aws = { :key => 'YOUR KEY', :secret => 'YOUR SECRET' }
end

**Note that when using the SQS Queue only the MicroQ's started via command-line will actually process messages**

# Then just use the queues in your workers
class SomeWorker
  worker :queue => :critical
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
