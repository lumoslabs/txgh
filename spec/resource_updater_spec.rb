require 'spec_helper'
require 'helpers/standard_txgh_setup'

include Txgh

describe ResourceUpdater do
  include StandardTxghSetup

  let(:updater) do
    ResourceUpdater.new(transifex_project, github_repo, logger)
  end

  let(:branch) { nil }
  let(:ref) { nil }
  let(:resource) { tx_config.resource(resource_slug, ref) }
  let(:commit_sha) { '8765309' }

  let(:modified_files) do
    [{ 'path' => resource.source_file, 'sha' => 'def456' }]
  end

  let(:translations) do
    YAML.load("|
      en:
        welcome: Hello
        goodbye: Goodbye
        new_phrase: I'm new
    ")
  end

  before(:each) do
    tree_sha = 'abc123'

    allow(github_api).to(
      receive(:get_commit).with(repo_name, commit_sha) do
        { 'commit' => { 'tree' => { 'sha' => tree_sha } } }
      end
    )

    allow(github_api).to(
      receive(:tree).with(repo_name, tree_sha) do
        { 'tree' => modified_files }
      end
    )

    modified_files.each do |file|
      allow(github_api).to(
        receive(:blob).with(repo_name, file['sha']) do
          { 'content' => translations, 'encoding' => 'utf-8' }
        end
      )
    end
  end

  it 'correctly uploads modified files to transifex' do
    modified_files.each do |file|
      expect(transifex_api).to(
        receive(:create_or_update) do |resource, content|
          expect(resource.source_file).to eq(file['path'])
          expect(content).to eq(translations)
        end
      )
    end

    updater.update_resource(resource, commit_sha)
  end

  it 'fires the transifex.resource.updated event' do
    allow(transifex_api).to receive(:create_or_update)

    expect { updater.update_resource(resource, commit_sha) }.to(
      change { Txgh.events.published.size }.by(1)
    )

    event = Txgh.events.published.first
    expect(event[:channel]).to eq('transifex.resource.updated')

    options = event[:options]
    expect(options[:project].name).to eq(project_name)
    expect(options[:repo].name).to eq(repo_name)
    expect(options[:sha]).to eq(commit_sha)
    expect(options[:resource].original_resource_slug).to eq(resource_slug)
  end

  context 'when asked to process all branches' do
    let(:branch) { 'all' }
    let(:ref) { 'heads/master' }

    it 'uploads by branch name if asked' do
      allow(transifex_api).to receive(:resource_exists?).and_return(false)

      modified_files.each do |file|
        expect(transifex_api).to(
          receive(:create) do |resource, content, categories|
            expect(resource.source_file).to eq(file['path'])
            expect(content).to eq(translations)
            expect(categories).to include("branch:#{ref}")
          end
        )
      end

      updater.update_resource(resource, commit_sha)
    end

    it 'adds categories when passed in' do
      expect(transifex_api).to receive(:resource_exists?).and_return(false)

      modified_files.each do |file|
        expect(transifex_api).to(
          receive(:create) do |resource, content, categories|
            expect(categories).to include('foo:bar')
          end
        )
      end

      updater.update_resource(resource, commit_sha, { 'foo' => 'bar' })
    end
  end

  context 'when asked to upload diffs' do
    let(:branch) { 'all' }
    let(:ref) { 'heads/my_branch' }
    let(:diff_point) { 'heads/diff_point' }
    let(:resource) do
      TxBranchResource.new(
        TxResource.new(
          project_name, resource_slug, 'YAML',
          'en', 'en.yml', '', 'translation_file'
        ),
        ref
      )
    end

    it 'uploads a diff instead of the whole resource' do
      expect(github_api).to(
        receive(:download)
          .with(repo_name, 'en.yml', diff_point)
          .and_return(YAML.load("|
            en:
              welcome: Hello
              goodbye: Goodbye
          "))
      )

      diff = YAML.load(%Q(|
        en:
          new_phrase: ! "I'm new"
      ))

      expect(updater).to(
        receive(:upload_by_branch).with(resource, diff, anything)
      )

      updater.update_resource(resource, commit_sha)
    end

    context 'when asked to upload the diff point' do
      let(:ref) { diff_point }

      it 'uploads the whole resource' do
        expect(updater).to(
          receive(:upload_by_branch).with(resource, translations, anything)
        )

        updater.update_resource(resource, commit_sha)
      end
    end
  end
end
