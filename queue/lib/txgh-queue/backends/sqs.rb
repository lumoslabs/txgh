require 'txgh'

module TxghQueue
  module Backends
    module Sqs
      autoload :Config,        'txgh-queue/backends/sqs/config'
      autoload :Consumer,      'txgh-queue/backends/sqs/consumer'
      autoload :Producer,      'txgh-queue/backends/sqs/producer'
      autoload :Queue,         'txgh-queue/backends/sqs/queue'
      autoload :RetryLogic,    'txgh-queue/backends/sqs/retry_logic'

      class << self
        def producer_for(queue_name, logger = Txgh::TxLogger.logger)
          Producer.new(Config.get_queue(queue_name), logger)
        end

        def consumer_for(queue_names, logger = Txgh::TxLogger.logger)
          queues = Array(queue_names).map do |queue_name|
            Config.get_queue(queue_name)
          end

          Consumer.new(queues, logger)
        end
      end
    end
  end
end
