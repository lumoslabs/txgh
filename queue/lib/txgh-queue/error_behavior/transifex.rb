require 'txgh'

module TxghQueue
  class ErrorBehavior
    class Transifex
      ERROR_CLASSES = {
        Txgh::TransifexApiError          => Response.retry_with_delay
        Txgh::TransifexNotFoundError     => Response.fail
        Txgh::TransifexUnauthorizedError => Response.fail
      }

      class << self
        def can_handle?(error_or_response)
          ERROR_CLASSES.any? { |klass, _| error_or_response.class == klass }
        end

        def handle(error)
          ERROR_CLASSES[error.class]
        end
      end
    end
  end
end
