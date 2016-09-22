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
          payload_json = payload.to_json
          new_message = queue.send_message(payload.to_json, options)

          logger.info(
            "Enqueued new message with id #{new_message.message_id} and params "\
              "#{payload_json}"
          )
        end
      end
    end
  end
end
