module TxghQueue
  class ErrorBehavior
    class ServerResponse
      class << self
        def can_handle?(error_or_response)
          error_or_response.is_a?(TxghServer::Response)
        end

        def handle(response)
          case response.status.to_i / 100
            when 2
              Response.ok
            else
              Response.fail
          end
        end
      end
    end
  end
end
