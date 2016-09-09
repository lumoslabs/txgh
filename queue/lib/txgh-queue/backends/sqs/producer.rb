require 'json'

module TxghQueue
  module Backends
    module Sqs
      class Producer
        attr_reader :queue, :logger

        def initialize(queue, logger)
          @queue = queue
          @logger = logger
        end

        def enqueue(payload, options = {})
          queue.send_message(payload.to_json, options)
        end
      end
    end
  end
end
