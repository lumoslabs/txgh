module TxghQueue
  class Response
    class << self
      def retry_without_delay
        @retry ||= new(retry_type: :retry_without_delay)
      end

      def retry_with_delay
        @retry_with_delay ||= new(retry_type: :retry_with_delay)
      end

      def fail
        @fail ||= new(retry_type: :fail)
      end

      def ok
        @ok ||= new(retry_type: :none)
      end
    end

    attr_reader :retry_type, :delay  # in seconds

    def initialize(options = {})
      @retry_type = options.fetch(:retry_type)
    end

    def retry?
      retry_with_delay? || retry_without_delay?
    end

    def retry_with_delay?
      retry_type == :retry_with_delay
    end

    def retry_without_delay?
      retry_type == :retry_without_delay
    end

    def fail?
      retry_type == :fail
    end

    def ok?
      retry_type == :none
    end

    def to_s
      retry_type.to_s
    end
  end
end
