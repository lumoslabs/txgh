require 'json'
require 'uri'

module TxghServer
  module Webhooks
    module Transifex
      class RequestHandler
        class << self
          def handle_request(request, logger)
            new(request, logger).handle_request
          end
        end

        include ResponseHelpers

        attr_reader :request, :logger

        def initialize(request, logger)
          @request = request
          @logger = logger
        end

        def handle_request
          if publish_event
            # the event handled the request
            return respond_with(204, '')  # no content
          end

          handle_safely do
            handler = TxghServer::Webhooks::Transifex::HookHandler.new(
              project: config.transifex_project,
              repo: config.git_repo,
              resource_slug: payload[:resource],
              language: payload[:language],
              logger: logger
            )

            handler.execute
          end
        end

        private

        def publish_event
          if Txgh.events.channel_hash.include?('transifex.webhook_received')
            Txgh.events.publish(
              'transifex.webhook_received', {
                payload: payload,
                raw_payload: raw_payload,
                signature: TransifexRequestAuth.signature_from(request),
                url: request.env['HTTP_X_TX_URL'],
                date_str: request.env['HTTP_DATE'],
                http_verb: request.request_method
              }
            )
          end
        end

        def handle_safely
          if authentic_request?
            yield
          else
            respond_with_error(401, 'Unauthorized')
          end
        rescue => e
          respond_with_error(500, "Internal server error: #{e.message}", e)
        end

        def authentic_request?
          if project.webhook_protected?
            TransifexRequestAuth.authentic_request?(
              request, project.webhook_secret
            )
          else
            true
          end
        end

        def project
          config.transifex_project
        end

        def config
          @config ||= Txgh::Config::KeyManager.config_from_project(payload[:project])
        end

        def raw_payload
          @raw_payload ||= begin
            request.body.rewind
            request.body.read
          end
        end

        def payload
          @payload ||= Txgh::Utils.deep_symbolize_keys(
            case request.env['CONTENT_TYPE']
              when 'application/json'
                JSON.parse(raw_payload)
              else
                Hash[URI.decode_www_form(raw_payload)]
            end
          )
        end

      end
    end
  end
end
