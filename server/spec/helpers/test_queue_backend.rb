class TestQueueBackend
  class << self
    def producer_for(event, logger = Txgh::TxLogger.logger)
      producers[event] ||= TestQueueProducer.new(event, logger)
    end

    def consumer_for(event, logger = Txgh::TxLogger.logger)
      consumers[event] ||= TestQueueConsumer.new(event, logger)
    end

    def reset!
      @producers = nil
      @consumers = nil
    end

    private

    def producers
      @producers ||= {}
    end

    def consumers
      @consumers ||= {}
    end
  end
end

class TestQueueProducer
  attr_reader :queue_names, :logger, :enqueued_jobs

  def initialize(event, logger)
    @event = event
    @logger = logger
    @enqueued_jobs = []
  end

  def enqueue(payload, options = {})
    enqueued_jobs << { payload: payload, options: options }
  end
end

class TestQueueConsumer
  attr_reader :queue_names, :logger

  def initialize(event, logger)
    @event = event
    @logger = logger
  end

  def work
  end
end
