module TxghQueue
  class TestBackend
    class << self
      def producer_for(event, logger = Txgh::TxLogger.logger)
        TestProducer.new(event, logger)
      end

      def consumer_for(event, logger = Txgh::TxLogger.logger)
        TestConsumer.new(event, logger)
      end
    end
  end

  class TestProducer
    attr_reader :queue_names, :logger

    def initialize(event, logger)
      @event = event
      @logger = logger
    end

    def enqueue(payload, options = {})
    end
  end

  class TestConsumer
    attr_reader :queue_names, :logger

    def initialize(event, logger)
      @event = event
      @logger = logger
    end

    def work
    end
  end
end
