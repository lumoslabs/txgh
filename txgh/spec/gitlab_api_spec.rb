require 'spec_helper'
require 'base64'

describe Txgh::GitlabApi do
  let(:client) { double(:client) }
  let(:api) { described_class.create_from_client(client, repo) }
  let(:repo) { 'my_org/my_repo' }
  let(:sha) { 'abc123' }
  let(:gitlab_response) do
    OpenStruct.new({
      code: 404,
      request: double(base_uri: 'https://gitlab.com/api/v3', path: '/foo'),
      parsed_response: Gitlab::ObjectifiedHash.new(
        error_description: 'Displayed error_description',
        error: 'also will not be displayed'
      )
    })
  end

  shared_examples 'an update_contents flow' do
    it 'updates the given file contents' do
      new_contents = 'def456'

      expect(client).to(
        receive(:get_file)
          .with(repo, path, url_safe_branch)
          .and_return(double(blob_id: old_sha))
      )

      expect(client).to(
        receive(:edit_file)
          .with(repo, path, url_safe_branch, new_contents, 'message')
      )

      api.update_contents(branch, [{ path: path, contents: new_contents }], 'message')
    end

    it "doesn't update the file contents if the file hasn't changed" do
      expect(client).to(
        receive(:get_file)
          .with(repo, path, url_safe_branch)
          .and_return(double(blob_id: old_sha))
      )

      expect(client).to_not receive(:edit_file)

      api.update_contents(branch, [{ path: path, contents: old_contents }], 'message')
    end

    it "creates the file if it doesn't already exist" do
      new_contents = 'foobar'
      expect(client).to receive(:get_file).and_raise(::Gitlab::Error::NotFound.new(gitlab_response))

      expect(client).to(
        receive(:edit_file)
          .with(repo, path, url_safe_branch, new_contents, 'message')
      )

      api.update_contents(branch, [{ path: path, contents: new_contents }], 'message')
    end
  end

  shared_examples 'a download flow' do
    it 'downloads the file from the given branch' do
      expect(client).to(
        receive(:get_file)
          .with(repo, path, url_safe_branch)
          .and_return(double(content: 'content', encoding: 'utf-8'))
      )

      expect(api.download(path, branch)).to eq({ content: 'content', path: path })
    end

    it 'encodes the string using the encoding specified in the response' do
      content = 'ありがと'.encode('UTF-16')

      expect(client).to(
        receive(:get_file)
          .with(repo, path, url_safe_branch)
          .and_return(double(content: content, encoding: 'utf-16'))
      )

      result = api.download(path, branch)
      expect(result[:content].encoding).to eq(Encoding::UTF_16)
      expect(result[:content]).to eq(content)
    end

    it 'automatically decodes base64-encoded content' do
      expect(client).to(
        receive(:get_file)
          .with(repo, path, url_safe_branch)
          .and_return(double(content: Base64.encode64('content'), encoding: 'base64'))
      )

      expect(api.download(path, branch)).to eq({ content: 'content', path: path })
    end
  end

  describe '#update_contents' do
    let(:path) { 'path/to/file.txt' }
    let(:old_contents) { 'abc123' }
    let(:old_sha) { Txgh::Utils.git_hash_blob(old_contents) }

    context 'when master branch' do
      let(:branch) { 'master' }
      let(:url_safe_branch) { 'master' }

      it_behaves_like 'an update_contents flow'
    end

    context 'when feature branch' do
      let(:branch) { 'feature/foo-ticket' }
      let(:url_safe_branch) { 'feature%2Ffoo-ticket' }

      it_behaves_like 'an update_contents flow'
    end
  end

  describe '#get_ref' do
    context 'when ref is a sha' do
      it 'retrieves the given ref (i.e. branch) using the client' do
        expect(client).to receive(:commit).with(repo, sha) { double(short_id: '0') }
        api.get_ref(sha)
      end
    end

    context 'when ref is a master branch' do
      let(:sha) { 'master' }

      it 'retrieves the given ref (i.e. branch) using the client' do
        expect(client).to receive(:commit).with(repo, sha) { double(short_id: '0') }
        api.get_ref(sha)
      end
    end

    context 'when ref is a feature branch' do
      let(:sha) { 'feature/foo-ticket' }
      let(:url_safe_sha) { 'feature%2Ffoo-ticket' }

      it 'retrieves the given ref (i.e. branch) using the client' do
        expect(client).to receive(:commit).with(repo, url_safe_sha) { double(short_id: '0') }
        api.get_ref(sha)
      end
    end
  end

  describe '#download' do
    let(:path) { 'path/to/file.xyz' }

    context 'when master branch' do
      let(:branch) { 'master' }
      let(:url_safe_branch) { 'master' }

      it_behaves_like 'a download flow'
    end

    context 'when feature branch' do
      let(:branch) { 'feature/foo-ticket' }
      let(:url_safe_branch) { 'feature%2Ffoo-ticket' }

      it_behaves_like 'a download flow'
    end
  end

  describe '#create_status' do
    let(:gitlab_response) do
      OpenStruct.new({
        code: 404,
        request: double(base_uri: 'https://gitlab.com/api/v3', path: '/foo'),
        parsed_response: Gitlab::ObjectifiedHash.new(
          error_description: 'Cannot transition status via :enqueue from :pending',
          error: 'also will not be displayed'
        )
      })
    end

    it 'does not raise error if cannot change status' do
      expect(client).to receive(:update_commit_status).and_raise(::Gitlab::Error::BadRequest.new(gitlab_response))

      api.create_status('sha', 'state', {})
    end
  end
end
