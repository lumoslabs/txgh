module Txgh
  module Config
    module Providers
      class GitProvider
        SCHEME = 'git'

        class << self
          def supports?(scheme)
            scheme == SCHEME
          end

          def load(payload, parser, options = {})
            new(payload, parser, options).config
          end
        end

        attr_reader :payload, :parser

        def initialize(payload, parser, options = {})
          @payload, inline_ref = parse_payload(payload)
          @parser = parser
          @ref = inline_ref || options[:ref]
          @github_repo = options[:github_repo]
        end

        def config
          parser.load(download)
        end

        private

        def parse_payload(payload)
          if payload.include?('@')
            payload.split('@')
          else
            [payload, nil]
          end
        end

        def download
          github_repo.api.download(github_repo.name, payload, ref)
        rescue Octokit::NotFound
          raise ConfigNotFoundError, "Config file #{payload} not found in #{ref}"
        end

        def ref
          unless @ref
            raise TxghError,
              "TX_CONFIG specified a file from git but did not provide a ref."
          end

          @ref
        end

        def github_repo
          unless @github_repo
            raise TxghError,
              "TX_CONFIG specified a file from git but did not provide a repo."
          end

          @github_repo
        end
      end
    end
  end
end
