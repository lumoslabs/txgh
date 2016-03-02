require 'spec_helper'
require 'helpers/nil_logger'
require 'helpers/standard_txgh_setup'

include Txgh
include Txgh::Handlers::Transifex

describe HookHandler do
  include StandardTxghSetup

  let(:requested_resource_slug) do
    resource_slug
  end

  let(:handler) do
    HookHandler.new(
      project: transifex_project,
      repo: github_repo,
      resource_slug: requested_resource_slug,
      language: language,
      logger: logger
    )
  end

  before(:each) do
    allow(transifex_api).to(receive(:download)) do |resource, language|
      expect(resource.project_slug).to eq(project_name)
      expect(resource.resource_slug).to eq(requested_resource_slug)
      translations
    end
  end

  it 'downloads translations and pushes them to the correct branch (head)' do
    expect(github_api).to(
      receive(:commit).with(
        repo_name, "heads/#{branch}", "translations/#{language}/sample.po", translations
      )
    )

    response = handler.execute
    expect(response.status).to eq(200)
    expect(response.body).to eq(true)
  end

  it "responds with an error if the config can't be found" do
    expect(handler).to receive(:tx_config).and_return(nil)
    response = handler.execute
    expect(response.status).to eq(404)
    expect(response.body).to eq([
      { error: "Could not find configuration for branch 'heads/#{branch}'" }
    ])
  end

  context 'with a non-existent resource' do
    let(:requested_resource_slug) { 'foobarbazboo' }

    it "responds with an error if the resource can't be found" do
      response = handler.execute
      expect(response.status).to eq(404)
      expect(response.body).to eq(
        [{ error: "Could not find resource '#{requested_resource_slug}' in config" }]
      )
    end
  end

  context 'when asked to process all branches' do
    let(:branch) { 'all' }
    let(:ref) { 'heads/my_branch' }

    let(:requested_resource_slug) do
      'my_resource-heads_my_branch'
    end

    it 'pushes to the individual branch' do
      expect(transifex_api).to receive(:get_resource) do
        { 'categories' => ["branch:#{ref}"] }
      end

      expect(github_api).to(
        receive(:commit).with(
          repo_name, ref, "translations/#{language}/sample.po", translations
        )
      )

      response = handler.execute
      expect(response.status).to eq(200)
      expect(response.body).to eq(true)
    end
  end

  context 'with a tag instead of a branch' do
    let(:branch) { 'tags/my_tag' }

    it 'downloads translations and pushes them to the tag' do
      expect(github_api).to(
        receive(:commit).with(
          repo_name, "tags/my_tag", "translations/#{language}/sample.po", translations
        )
      )

      response = handler.execute
      expect(response.status).to eq(200)
      expect(response.body).to eq(true)
    end
  end
end