require 'json'
require 'txgh'

module TxghQueue
  module Backends
    module Sqs
      class HistorySequence
        extend Forwardable

        class << self
          def from_message(message)
            if attribute = message.message_attributes['history_sequence']
              new(JSON.parse(attribute.string_value))
            else
              new([])
            end
          end

          def from_h(hash)
            new(
              JSON.parse(
                Txgh::Utils.deep_symbolize_keys(hash)
                  .fetch(:history_sequence, {})
                  .fetch(:string_value, nil)
              )
            )
          end
        end

        attr_reader :sequence

        def_delegators :sequence, :[], :<<, :first, :last, :size, :length

        def initialize(sequence)
          @sequence = Txgh::Utils.deep_symbolize_keys(sequence)
        end

        def add(obj)
          sequence << obj
        end

        def to_h
          { string_value: sequence.to_json, data_type: 'String' }
        end

        def dup
          # use json serialization to deep copy the sequence
          self.class.new(JSON.parse(sequence.to_json))
        end

        def current
          sequence.last
        end

        def partition
          sequence.each_with_object([]) do |elem, ret|
            if ret.last && ret.last.last == elem[:status]
              ret.last << elem[:status]
            elsif elem[:status]
              ret << [elem[:status]]
            end
          end
        end
      end
    end
  end
end
