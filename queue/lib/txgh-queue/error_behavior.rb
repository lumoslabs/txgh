require 'txgh'

module TxghQueue
  class UnexpectedError < StandardError; end
  class UnexpectedResponse < StandardError; end

  class ErrorBehavior
    autoload :Github,         'txgh-queue/error_behavior/github'
    autoload :ServerResponse, 'txgh-queue/error_behavior/server_response'
    autoload :StandardErrors, 'txgh-queue/error_behavior/standard_errors'
    autoload :Transifex,      'txgh-queue/error_behavior/transifex'

    BEHAVIOR_CLASSES = [
      ServerResponse, Github, Transifex, TxghErrors, StandardErrors
    ]

    class << self
      def wrap(&block)
        new(block).execute
      end
    end

    attr_reader :block

    def initialize(block)
      @block = block
    end

    def execute
      response = block.call
      handle_response(response)
    rescue StandardError => e
      Txgh.events.publish_error(e, raise_if_no_subscribers: false)
      handle_error(e)
    end

    private

    def handle_response(response)
      klass = find_behavior_class(response)
      raise(UnexpectedResponse, "#{response.status} #{response.body}") unless klass
      klass.handle(response)
    end

    def handle_error(error)
      klass = find_behavior_class(error)
      raise(UnexpectedError, error.message) unless klass
      klass.handle(error)
    end

    def find_behavior_class(response_or_error)
      BEHAVIOR_CLASSES.find do |klass|
        klass.can_handle?(response_or_error)
      end
    end
  end
end
