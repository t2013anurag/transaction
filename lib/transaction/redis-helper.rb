# frozen_string_literal: true

require 'redis'

class RedisHelper
  attr_writer :redis

  def initialize(hash = {})
    @redis = if hash.instance_of?(Redis)
               hash
             else
               Redis.new(hash)
             end
  end

  def self.redis
    # use default redis if not set
    @redis ||= Redis.new
  end

  def redis_get(transaction_id)
    @redis.get(transaction_id)
  end

  def redis_set(key, value)
    @redis.set(key, value)
  end

  def redis_delete(transaction_id)
    @redis.del(transaction_id)
  end
end
