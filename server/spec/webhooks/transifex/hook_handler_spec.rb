require 'spec_helper'
require 'helpers/nil_logger'
require 'helpers/standard_txgh_setup'

describe TxghServer::Webhooks::Transifex::HookHandler do
  include StandardTxghSetup

  let(:requested_resource_slug) do
    resource_slug
  end

  let(:handler) do
    TxghServer::Webhooks::Transifex::HookHandler.new(
      project: transifex_project,
      repo: github_repo,
      resource_slug: requested_resource_slug,
      language: language,
      logger: logger
    )
  end

  let(:downloader) do
    instance_double(Txgh::ResourceDownloader)
  end

  let(:file_name) do
    "translations/#{language}/sample.yml"
  end

  before(:each) do
    allow(Txgh::ResourceDownloader).to receive(:new).and_return(downloader)
    allow(downloader).to(receive(:first)).and_return([
      "translations/#{language}/sample.yml", translations
    ])

    allow(github_api).to receive(:get_ref).and_return(
      object: { sha: '123abcshashasha' }
    )
  end

  it 'downloads translations and pushes them to the correct branch (head)' do
    expect(github_api).to(
      receive(:update_contents).with(
        "heads/#{branch}",
        [{ path: "translations/#{language}/sample.yml", contents: translations }],
        "Updating #{language} translations in #{file_name}"
      )
    )

    expect(Txgh::GithubStatus).to(
      receive(:update).with(transifex_project, github_repo, ref)
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
        receive(:update_contents).with(
          ref,
          [{ path: "translations/#{language}/sample.yml", contents: translations }],
          "Updating #{language} translations in #{file_name}"
        )
      )

      expect(Txgh::GithubStatus).to(
        receive(:update).with(transifex_project, github_repo, ref)
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
        receive(:update_contents).with(
          "tags/my_tag",
          [{ path: "translations/#{language}/sample.yml", contents: translations }],
          "Updating #{language} translations in #{file_name}"
        )
      )

      expect(Txgh::GithubStatus).to(
        receive(:update).with(transifex_project, github_repo, branch)
      )

      response = handler.execute
      expect(response.status).to eq(200)
      expect(response.body).to eq(true)
    end
  end

  context 'with an unsupported language' do
    let(:language) { 'pt' }
    let(:supported_languages) { ['ja'] }

    it "doesn't make a commit" do
      expect(github_api).to_not receive(:update_contents)

      response = handler.execute
      expect(response.status).to eq(304)
      expect(response.body).to eq(true)
    end
  end
end
