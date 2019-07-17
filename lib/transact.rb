require 'transact/version'
require 'securerandom'
require 'redis'
require 'json'

module Transact
  class << self
    attr_accessor :configuration
  end

  STATUSES = {
    queued: 0,
    processing: 1,
    success: 2,
    error: 3
  }.freeze

  DEFAULT_ATTRIBUTES = {
    status: :queued,
    pusher_trigger: false,
    event: 'status'
  }.freeze

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :redis_client

    def initialize
      @redis_client = Redis.new
    end
  end

  class Client
    attr_reader :transaction_id, :status, :attributes

    def initialize(transaction_id: nil, options: {})
      @transaction_id = transaction_id || "transact-#{SecureRandom.urlsafe_base64(16)}"
      @config = Configuration.new

      options = DEFAULT_ATTRIBUTES.merge(options)

      @attributes = parsed_attributes || {}
      update_attributes(options) if @attributes.empty?

      @status = @attributes[:status]
    end

    def update_attributes(options)
      @attributes = symbolize_keys!(@attributes.merge!(options))
      redis_set(@transaction_id, @attributes.to_json)
      @status = @attributes[:status]
    end

    def clear!
      @attributes = @status = nil
      redis_delete(@transaction_id)
    end

    private

    def parsed_attributes
      data = redis_get(@transaction_id)
      return nil if data.nil?

      begin
        response = JSON.parse(data)
        raise 'Invalid response from redis. Expected Hash' unless response.is_a? Hash

        response = symbolize_keys!(response)
      rescue JSON::ParserError
        raise 'Invalid attempt to update the attributes'
      end

      response
    end

    def symbolize_keys!(response = @attributes)
      response.keys.each do |key|
        response[(begin
                    key.to_sym
                  rescue StandardError
                    key
                  end) || key] = response.delete(key)
      end

      response
    end

    # redis methods
    def redis_get(key)
      @config.redis_client.get(key)
    end

    def redis_set(key, value)
      @config.redis_client.set(key, value)
    end

    def redis_delete(key)
      @config.redis_client.del(key)
    end
  end

  class Error < StandardError; end
end
