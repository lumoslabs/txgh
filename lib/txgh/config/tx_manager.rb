module Txgh
  module Config
    class TxManager
      class << self
        include ProviderSupport

        def tx_config(transifex_project, github_repo, ref = nil)
          options = { github_repo: github_repo, ref: ref }
          scheme, payload = split_uri(transifex_project.tx_config_uri)

          if provider = provider_for(scheme)
            provider.load(payload, options)
          else
            raise Txgh::InvalidProviderError,
              "Couldn't find a provider for the '#{scheme}' scheme. Please "\
              "make sure txgh is configured properly."
          end
        end
      end
    end
  end
end
