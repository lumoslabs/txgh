module TxghQueue
  class Processor
    def process(payload)
    end

    private

    def perform(payload)
      raise NotImplementedError
    end
  end
end
