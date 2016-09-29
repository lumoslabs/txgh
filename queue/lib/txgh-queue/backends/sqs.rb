require 'txgh'

module TxghQueue
  module Backends
    module Sqs
      autoload :Config,            'txgh-queue/backends/sqs/config'
      autoload :Consumer,          'txgh-queue/backends/sqs/consumer'
      autoload :Job,               'txgh-queue/backends/sqs/job'
      autoload :MessageAttributes, 'txgh-queue/backends/sqs/message_attributes'
      autoload :Producer,          'txgh-queue/backends/sqs/producer'
      autoload :Queue,             'txgh-queue/backends/sqs/queue'
      autoload :RetryLogic,        'txgh-queue/backends/sqs/retry_logic'
      autoload :RetrySequence,     'txgh-queue/backends/sqs/retry_sequence'

      class << self
        def producer_for(event, logger = Txgh::TxLogger.logger)
          Producer.new(get_queues(queue_names), logger)
        end

        def consumer_for(event, logger = Txgh::TxLogger.logger)
          Consumer.new(get_queues(queue_names), logger)
        end

        private

        def find_queues_for(event)
          Config.queues.select { |queue| queue.events.include?(event) }
        end
      end
    end
  end
end
