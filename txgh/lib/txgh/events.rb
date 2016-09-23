module Txgh
  class Events
    ERROR_CHANNEL = 'errors'

    attr_reader :channel_hash

    def initialize
      @channel_hash = Hash.new { |h, k| h[k] = [] }
    end

    def subscribe(channel, &block)
      channel_hash[channel] << block
    end

    def publish(channel, options = {})
      channel_hash.fetch(channel, []).each do |callback|
        callback.call(options)
      end
    rescue => e
      publish_error(e)
    end

    def channels
      channel_hash.keys
    end

    def publish_error(e, options = {})
      # if nobody has subscribed to error events, raise original error
      callbacks = channel_hash.fetch(ERROR_CHANNEL) do
        raise(e) if options.fetch(:raise_if_no_subscribers, true)
        []
      end

      callbacks.each do |callback|
        callback.call(e, options.fetch(:params, {}))
      end
    end
  end
end
