# frozen_string_literal: true

require 'transaction/version'
require 'securerandom'
require 'redis'
require 'json'
require 'transaction/helper'
require 'transaction/client'

module Transaction
  STATUSES = %i[queued processing success error].freeze

  DEFAULT_ATTRIBUTES = {
    status: :queued
  }.freeze

  def self.configure
    yield self
  end

  def self.redis=(hash = {})
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

  def self.pubsub_client=(client:, trigger:, channel_name: nil, event: 'status')
    @client = client
    @trigger = trigger
    @event = event
    @channel_name = channel_name
  end

  def self.pubsub_client
    return if @client.nil? || @trigger.nil?

    {
      client: @client,
      trigger: @trigger,
      event: @event,
      channel_name: @channel_name
    }
  end

  class Error < StandardError; end
end
