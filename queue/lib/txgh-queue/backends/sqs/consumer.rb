require 'json'

module TxghQueue
  module Backends
    module Sqs
      class Consumer
        attr_reader :queues, :logger

        def initialize(queues, logger)
          @queues = queues
          @logger = logger
        end

        def work
          params = { message_attribute_names: %w(retry_sequence) }

          queues.each do |queue|
            queue.receive_message(params).messages.each do |message|
              logger.info("Received message from #{queue.name}, id: #{message.message_id}")
              Job.new(message, queue, logger).complete
            end
          end
        end
      end
    end
  end
end
