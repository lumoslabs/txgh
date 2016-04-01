module Txgh
  class EmptyResourceContents
    attr_reader :tx_resource

    def initialize(tx_resource)
      @tx_resource = tx_resource
    end

    def phrases
      []
    end

    def write_to(stream, language = nil)
    end

    def to_s(language = nil)
      ''
    end

    def to_h
      {}
    end

    def diff(other_contents)
      other_contents
    end

    def diff_hash(other_contents)
      DiffCalculator::INCLUDED_STATES.each_with_object({}) do |state, ret|
        ret[state] = []
      end
    end

    def merge(other_contents, diff_hash)
      other_contents
    end

    def empty?
      true
    end
  end
end
