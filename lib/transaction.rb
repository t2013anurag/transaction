# frozen_string_literal: true

require 'transaction/version'
require 'securerandom'
require 'json'
require 'transaction/helper'
require 'transaction/redis-helper'

module Transaction
  STATUSES = %i[queued processing success error].freeze

  DEFAULT_ATTRIBUTES = {
    status: :queued
  }.freeze

  def self.configure
    yield self
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

  class Client
    attr_reader :transaction_id, :status, :attributes

    def initialize(transaction_id: nil, options: {})
      @transaction_id = transaction_id ||
                        "transact-#{SecureRandom.urlsafe_base64(16)}"
      @redis_client = RedisHelper.new
      @pubsub_client = Transaction.pubsub_client

      options = DEFAULT_ATTRIBUTES.merge(options)

      @attributes = parsed_attributes || {}
      update_attributes(options) if @attributes.empty?

      @status = @attributes[:status].to_s
    end

    def update_attributes(options)
      unless options.is_a? Hash
        raise ArgumentError, 'Invalid type. Expected Hash'
      end

      @attributes = symbolize_keys!(@attributes.merge!(options))
      @redis_client.redis_set(@transaction_id, @attributes.to_json)
      @status = @attributes[:status].to_s
    end

    def update_status(status)
      status = status.to_sym
      raise 'Invalid Status' unless STATUSES.include?(status.to_sym)

      update_attributes(status: status)
    end

    def start!
      update_status(:processing)
      trigger_event!(message: 'Processing')
    end

    def finish!(status: 'success', clear: false, data: {})
      update_status(status)
      trigger_event!({ message: 'Done' }.merge(data))
      @redis_client.redis_delete(@transaction_id) if clear
    end

    def clear!
      @attributes = @status = nil
      @redis_client.redis_delete(@transaction_id)
    end

    def refresh!
      @attributes = parsed_attributes
      raise StandardError, 'Transaction expired' if @attributes.nil?

      @status = @attributes[:status].to_s
    end

    def trigger_event!(data = {})
      return if @pubsub_client.nil?

      data[:status] = @status
      channel_name = @pubsub_client[:channel_name] || @transaction_id
      client = @pubsub_client[:client]
      trigger = @pubsub_client[:trigger]
      event = @pubsub_client[:event]

      client.send(trigger, channel_name, event, data)
    end

    private

    def parsed_attributes
      data = @redis_client.redis_get(@transaction_id)
      return nil if data.nil?

      begin
        response = JSON.parse(data)
        raise 'Invalid type. Expected Hash' unless response.is_a? Hash

        response = symbolize_keys!(response)
      rescue JSON::ParserError
        raise 'Invalid attempt to update the attributes'
      end

      response
    end
  end

  class Error < StandardError; end
end
