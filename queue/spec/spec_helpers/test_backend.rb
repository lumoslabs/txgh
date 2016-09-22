module TxghQueue
  class TestBackend
    class << self
      def producer_for(queue_name, logger = Txgh::TxLogger.logger)
      end

      def consumer_for(queue_names, logger = Txgh::TxLogger.logger)
      end
    end
  end

  class TestProducer
  end

  class TestConsumer
  end
end
