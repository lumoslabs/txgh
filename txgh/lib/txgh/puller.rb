module Txgh
  class Puller
    attr_reader :project, :repo, :branch

    def initialize(project, repo, branch = nil)
      @project = project
      @repo = repo
      @branch = branch
    end

    def pull
      existing_resources = project.api.get_resources(project.name)
      slugs = existing_resources.map { |resource| resource['slug'] }

      resources = tx_config.resources.each_with_object([]) do |tx_resource, ret|
        if repo.process_all_branches?
          tx_resource = Txgh::TxBranchResource.new(tx_resource, branch)
        end

        next unless slugs.include?(tx_resource.resource_slug)
        ret << tx_resource
      end

      pull_resources(resources, &block)
    end

    def pull_resources(tx_resources)
      tx_resources.each do |tx_resource|
        pull_resource(tx_resource)
      end

      update_github_status_for(tx_resources)
    end

    def pull_resource(tx_resource)
      project.languages.each do |language_code|
        committer.commit_resource(tx_resource, branch, language_code)
      end
    end

    def pull_slug(resource_slug)
      pull_resource(tx_config.resource(resource_slug, branch))
    end

    private

    def update_github_status_for(tx_resources)
      return unless branch
      ref = repo.api.get_ref(branch)
      github_status = GithubStatus.new(project, repo, tx_resources)
      github_status.update(ref[:object][:sha])
    rescue Octokit::UnprocessableEntity
      # raised because we've tried to create too many statuses for the commit
    rescue Txgh::TransifexNotFoundError
      # raised if transifex resource can't be found
    end

    def committer
      @committer ||= Txgh::ResourceCommitter.new(project, repo)
    end

    def languages
      @languages ||= project.api.get_languages(project.name)
    end

    def tx_config
      @tx_config ||= Txgh::Config::TxManager.tx_config(project, repo, branch)
    end
  end
end
