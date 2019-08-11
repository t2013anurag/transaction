[![Gem Version](https://badge.fury.io/rb/transaction.svg)](https://badge.fury.io/rb/transaction)
[![Build Status](https://travis-ci.com/t2013anurag/transaction.svg?branch=master)](https://travis-ci.com/t2013anurag/transaction)
[![Maintainability](https://api.codeclimate.com/v1/badges/50600537b315c364fc28/maintainability)](https://codeclimate.com/github/t2013anurag/transaction/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/50600537b315c364fc28/test_coverage)](https://codeclimate.com/github/t2013anurag/transaction/test_coverage)
[![Depfu](https://badges.depfu.com/badges/bfb8415f8ae6c5c12f023ebc28d14c32/count.svg)](https://depfu.com/github/t2013anurag/transaction?project_id=8568)


# Transaction

Transaction is a small library which helps track the status of running/upcoming tasks. These tasks can be a cron job, background jobs or a simple method. Any task can be plugged into a transaction block.

Transaction uses ***Redis*** to store the current status along with the additional attributes(provided during the initialization or transaction update.)

The events within the transaction block can be published via ***Pubsub client(ex. Pusher, PubNub or any valid pubsub client)***. These events can be subscribed in the client app for the live status of the transaction.


## Requirements

Redis(>=3.0)

Valid Pubsub client if messages need to be published.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'transaction'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install transaction

## Usage

### Initializing Transaction gem -

In your rails app - create `config/transaction.rb`
```ruby

  # Ex. pusher looks like | any pubsub client can be used.
  require 'pusher'
  PubsubClient = Pusher::Client.new(
    app_id:"app_id",
    key: "app_key",
    secret: "app_secret",
    cluster: "cluster_info",
    use_tls: true
  )

  Transaction.configure do |config|
    config.redis = Redis.new # defaults to localhost
    config.pubsub_client = {client: PubsubClient, trigger: 'trigger'}
  end
```

There's an option to directly connect as well.
```ruby
  Transaction.redis = Redis.new(url: 'redis://redis_url:6379')
  Transaction.pubsub_client = {client: PubsubClient, trigger: 'trigger'}
```

The pubsub client accepts the following options -

param | description
|:-:|---
client  | Any valid pubsub client. Ex. Pusher, PubNub.
trigger | The method name which sends a message to a pubsub client. Ex. `'trigger'` for Pusher. `'publish'` for PubNub.
channel_name | (Optional) Channel in which the message be published. Defaults to the value of `transaction_id`.
event | (Optional) Event for which message will be published. Defaults to `'status'`


### Initializing a transaction
A transaction can be newly initialized or be found with the given transaction_id. If no transaction is found then a new transaction is created.
```ruby
  attributes = {created_at: Time.now, count: 0 }
  transaction = Transaction::Client.new(options: attributes) # creates a new instance of transaction
  transaction1 = Transaction::Client.new(transaction_id: transaction.transaction_id) # finds the transaction.
```

### Accepted methods for a transaction
The default status of any new transaction is **`queued`**.
Accepted statuses: **['queued', 'processing', 'success', 'error']**. Any transaction at any point will be in one of the states.

method | params | description
|:-:|---|---
start!  | - | moves to status `processing` from `queued`. Publishes `{message: Processing}` to pubsub client if enabled.
finish! | (status: 'success', clear: false, data: {}) | moves to the passed status (default: `success`). Any additional data passed is merged with default `{message: 'Done}'`. `clear = true` destroy the transaction entry from Redis cache.
clear!  | - | destroys the current entry from Redis cache.
refresh! | - | sync current instance transaction with the latest cache (Other instance of a transaction initiated with same transaction id can update the attributes. Hence `refresh!` is required.).
update_status | status | moves to the passed status. Raises `'Invalid Status'` error if the status is not in one of the **Accepted statuses** defined above.
update_attributes | options = {} | merges the passed options hash to the current attributes object.
trigger_event! | data = {} | publishes the data via pubsub. Current `status` along with-param data is published(Note: Pubsub client needs to be configured.)


### Ex 1: Simple transaction
```ruby
    def sum_numbers
      arr = (0...10_000).to_a
      options = { created_at: Time.now, total: arr.count  }
      transaction = Transaction::Client.new(options: options)

      transaction.start!
      puts transaction.status # Status moves from `queued` to `processing`

      count = 0
      (1..10_000).each do |i|
        # do some other stuff
        transaction.update_attributes(count: count += 1)
        # do some other stuff
      end

      transaction.finish! # By default moves to status 'success'.

      puts transaction.status # 'success'
      puts transaction.attributes # {:status=>:success, :created_at=>2019-07-19 06:06:43 +0530, :total=>10000, :count=>10000}
    end
```

### Ex 2: Initialize or find a transaction with a transaction id.
```ruby
    def task1
      transaction = Transaction::Client.new
      SomeWorkerJob.perform_later(transaction.transaction_id) # sidekiq or resque
    end

    class SomeWorkerJob < ApplicationJob
      queue_as :default

      def perform transaction_id
        tr = Transaction::Client.new(transaction_id: transaction_id) # intialize with given transaction_id
        tr.start!

        # do a bunch of stuff
        tr.finish!
      end
    end
```

### Keeping transactions in sync.
Let's say we have 2 transactions `t1` and `t2` both initialized with the same transaction id. If `t2` updates the transaction, then `t1` can simply refresh the transaction to get in sync with `t2`. Note: the transaction will be refreshed with the most recent values. (Versioning transaction updates ??? => Woah that's a nice PR idea.)
```ruby
  def task1
    transaction = Transaction::Client.new
    transaction.start!
    task2(transaction.transaction_id)

    puts transaction.status # 'processing'
    transaction.refresh!
    puts transaction.status # 'error'
  end

  def task2 transaction_id # in some other context altogether. Task 2 is not at all related to task 1.
    transaction = Transaction::Client.new(transaction_id: transaction_id)
    # do some stuff
    transaction.finish!('error')
  end
```

### Pushing messages to client via pubsub
If a task is running in the background and the client needs to know the status. PubSub can be configured to do so.
```ruby
   # configure pubsub client as defined above in Initializing Transaction gem

   def long_task
    transaction = Transaction::Client.new
    transaction.start!

    items = (0..10_000).to_a

    items.each do |index|
      transaction.trigger_event!(count: index, total: items.count)
      # do something
    end

    transaction.finish!(data: {count: items.count, total: items.count})
   end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/t2013anurag/transaction. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open-source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Transaction project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/t2013anurag/transaction/blob/master/CODE_OF_CONDUCT.md).
