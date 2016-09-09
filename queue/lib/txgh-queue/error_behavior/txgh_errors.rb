require 'txgh'

module TxghQueue
  class ErrorBehavior
    class TxghErrors
      ERROR_CLASSES = {
        Txgh::ConfigNotFoundError        => Response.fail
        Txgh::GitConfigNotFoundError     => Response.fail
        Txgh::InvalidProviderError       => Response.fail
        Txgh::ProjectConfigNotFoundError => Response.fail
        Txgh::RepoConfigNotFoundError    => Response.fail
        Txgh::TxghError                  => Response.fail
        Txgh::TxghInternalError          => Response.fail
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
