# MicroQ [![Build Status](https://travis-ci.org/bnorton/micro_q.png)](https://travis-ci.org/bnorton/micro_q)

MicroQ is a per-process asynchronous background queue.

It's simple startup and intuitive interface makes it the best choice for new and lagacy apps.

## Installation

Add this line to your Gemfile:

    gem 'micro_q'

    $ bundle

Or install it:

    $ gem install micro_q

## Usage

```ruby
# A typical worker
class MyWorker
  def perform
    # do some performing here
  end

  def update(options = {})
    # do some updating
   end
end
```

###Simple (default)

```ruby
# Using the async proxy API
MyWorker.async.perform

MyWorker.async.update(:user_id => user.id)

# Through the raw push API
MicroQ.push(:class => 'MyWorker') # Defaults to the perform method

# With a custom method
MicroQ.push(:class => 'MyWorker', :method => 'update', :args => [{:user_id => user.id}])
```

###Advanced

###Custom Loaders

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
