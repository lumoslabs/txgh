module TxghQueue
  module Backends
    module Sqs
      class MessageAttributes
        class << self
          def from_message(message)
            retry_sequence = RetrySequence.from_message(message)
            new(retry_sequence)
          end

          def from_h(hash)
            retry_sequence = RetrySequence.from_h(hash)
            new(retry_sequence)
          end
        end

        attr_reader :retry_sequence

        def initialize(retry_sequence)
          @retry_sequence = retry_sequence
        end

        def to_h
          { retry_sequence: retry_sequence.to_h }
        end

        def dup
          self.class.new(retry_sequence.dup)
        end
      end
    end
  end
end
