require 'octokit'

module TxghQueue
  class ErrorBehavior
    class Github
      ERROR_CLASSES = {
        Octokit::AbuseDetected           => Response.fail,
        Octokit::BadGateway              => Response.retry_without_delay,
        Octokit::BadRequest              => Response.fail,
        Octokit::ClientError             => Response.fail,
        Octokit::Conflict                => Response.fail,
        Octokit::Forbidden               => Response.fail,
        Octokit::InternalServerError     => Response.retry_with_delay,
        Octokit::MethodNotAllowed        => Response.fail,
        Octokit::NotAcceptable           => Response.fail,
        Octokit::NotFound                => Response.fail,
        Octokit::NotImplemented          => Response.fail,
        Octokit::OneTimePasswordRequired => Response.fail,
        Octokit::RepositoryUnavailable   => Response.retry_with_delay,
        Octokit::ServerError             => Response.retry_with_delay,
        Octokit::ServiceUnavailable      => Response.retry_with_delay,
        Octokit::TooManyLoginAttempts    => Response.retry_with_delay,
        Octokit::TooManyRequests         => Response.retry_with_delay,
        Octokit::Unauthorized            => Response.fail,
        Octokit::UnprocessableEntity     => Response.fail,
        Octokit::UnsupportedMediaType    => Response.fail,
        Octokit::UnverifiedEmail         => Response.fail
      }

      class << self
        def can_handle?(error_or_response)
          error_or_response.is_a?(Octokit::Error)
        end

        def handle(error)
          return klass if klass = ERROR_CLASSES[error.class]
          handle_other(error)
        end

        private

        def handle_other(error)
          Response.fail
        end
      end
    end
  end
end
