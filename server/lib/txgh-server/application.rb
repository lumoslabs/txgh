require 'sinatra'
require 'sinatra/json'
require 'sinatra/streaming'

module TxghServer
  module RespondWith
    def respond_with(resp)
      env['txgh.response'] = resp

      if resp.streaming?
        response.headers.merge!(resp.headers)

        stream do |out|
          begin
            resp.write_to(out)
          rescue => e
            Txgh.events.publish_error!(e)
          end
        end
      else
        status resp.status
        json resp.body
      end
    end
  end

  class Application < Sinatra::Base
    include TxghServer

    helpers Sinatra::Streaming
    helpers RespondWith

    configure do
      set :logging, nil
      logger = Txgh::TxLogger.logger
      set :logger, logger
    end

    get '/health_check' do
      respond_with(
        Response.new(200, {})
      )
    end

    get '/config' do
      config = Txgh::Config::KeyManager.config_from_project(params[:project_slug])
      branch = Txgh::Utils.absolute_branch(params[:branch])

      begin
        tx_config = Txgh::Config::TxManager.tx_config(
          config.transifex_project, config.git_repo, branch
        )

        data = tx_config.to_h
        data.merge!(branch_slug: Txgh::Utils.slugify(branch)) if branch

        status 200
        json data: data
      rescue Txgh::ConfigNotFoundError => e
        status 404
        json [{ error: e.message }]
      rescue => e
        status 500
        json [{ error: e.message }]
      end
    end

    get '/download.:format' do
      respond_with(
        DownloadHandler.handle_request(request, settings.logger)
      )
    end
  end

  # Hooks are protected endpoints used for data integration between Github and
  # Transifex. They live under the /hooks namespace (see config.ru)
  class WebhookEndpoints < Sinatra::Base
    include TxghServer::Webhooks
    helpers RespondWith

    configure do
      set :logging, nil
      logger = Txgh::TxLogger.logger
      set :logger, logger
    end

    post '/transifex' do
      respond_with(
        Transifex::RequestHandler.handle_request(request, settings.logger)
      )
    end

    post '/github' do
      respond_with(
        Github::RequestHandler.handle_request(request, settings.logger)
      )
    end

    post '/gitlab' do
      respond_with(
        TxghServer::Webhooks::Gitlab::RequestHandler.handle_request(request, settings.logger)
      )
    end
  end

  class TriggerEndpoints < Sinatra::Base
    include TxghServer::Triggers

    helpers RespondWith

    configure do
      set :logging, nil
      logger = Txgh::TxLogger.logger
      set :logger, logger
    end

    patch '/push' do
      respond_with(
        PushHandler.handle_request(request, settings.logger)
      )
    end

    patch '/pull' do
      respond_with(
        PullHandler.handle_request(request, settings.logger)
      )
    end
  end
end
