# MicroQ [![Build Status](https://travis-ci.org/bnorton/micro_q.png)](https://travis-ci.org/bnorton/micro_q)

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
  worker :update # sets up the dsl and adds additional async_ methods

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
MyWorker.async_perform
MyWorker.async_update(:user_id => user.id)
```

###Advanced

Safely using an ActiveRecord instance via the Custom Loader API 
```ruby
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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
