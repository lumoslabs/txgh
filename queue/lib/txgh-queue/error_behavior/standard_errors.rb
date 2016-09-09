module TxghQueue
  class ErrorBehavior
    class StandardErrors
      class << self
        def can_handle?(error_or_response)
          error_or_response.is_a?(StandardError)
        end

        def handle(response)
          Response.fail
        end
      end
    end
  end
end
