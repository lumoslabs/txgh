require 'base64'
require 'octokit'

module Txgh
  class GithubApi
    class << self
      def create_from_credentials(login, access_token, repo)
        create_from_client(
          Octokit::Client.new(login: login, access_token: access_token), repo
        )
      end

      def create_from_client(client, repo)
        new(client, repo)
      end
    end

    attr_reader :client, :repo

    def initialize(client, repo)
      @client = client
      @repo = repo
    end

    def tree(sha)
      client.tree(repo, sha, recursive: 1)
    end

    def blob(sha)
      client.blob(repo, sha)
    end

    def create_ref(branch, sha)
      client.create_ref(repo, branch, sha) rescue false
    end

    def update_contents(repo, branch, content_map, message)
      content_map.each do |path, new_contents|
        branch = Utils.relative_branch(branch)

        file = begin
          client.contents(repo, { path: path, ref: branch })
        rescue Octokit::NotFound
          nil
        end

        current_sha = file ? file[:sha] : '0' * 40
        new_sha = Utils.git_hash_blob(new_contents)
        options = { branch: branch }

        if current_sha != new_sha
          client.update_contents(
            repo, path, message, current_sha, new_contents, options
          )
        end
      end
    end

    def commit(repo, branch, content_map, message, allow_empty = false)
      parent = client.ref(repo, branch)
      base_commit = get_commit(repo, parent[:object][:sha])

      tree_data = content_map.map do |path, content|
        blob = client.create_blob(repo, content)
        { path: path, mode: '100644', type: 'blob', sha: blob }
      end

      tree_options = { base_tree: base_commit[:commit][:tree][:sha] }

      tree = client.create_tree(repo, tree_data, tree_options)
      commit = client.create_commit(
        repo, message, tree[:sha], parent[:object][:sha]
      )

      # don't update the ref if the commit introduced no new changes
      unless allow_empty
        diff = client.compare(repo, parent[:object][:sha], commit[:sha])
        return if diff[:files].empty?
      end

      # false means don't force push
      client.update_ref(repo, branch, commit[:sha], false)
    end

    def get_commit(sha)
      client.commit(repo, sha)
    end

    def get_ref(ref)
      client.ref(repo, ref)
    end

    def download(path, branch)
      contents = client.contents(repo, { path: path, ref: branch })
      return contents[:content] if contents[:encoding] == 'utf-8'
      return Base64.decode64(contents[:content])
    end

    def create_status(sha, state, options = {})
      client.create_status(repo, sha, state, options)
    end

  end
end
