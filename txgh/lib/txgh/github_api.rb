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

    def update_contents(branch, content_map, message)
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

    def get_commit(sha)
      client.commit(repo, sha)
    end

    def get_ref(ref)
      client.ref(repo, ref)
    end

    def download(path, branch)
      file = client.contents(repo, { path: path, ref: branch }).to_h

      if file.delete(:encoding) == 'base64'
        file[:content] = Base64.decode64(file[:content])
      end

      file
    end

    def create_status(sha, state, options = {})
      client.create_status(repo, sha, state, options)
    end

  end
end
