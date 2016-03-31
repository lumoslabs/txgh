module Txgh
  class ResourceDownloader
    include Enumerable

    attr_reader :project, :repo, :branch

    def initialize(project, repo, branch, options = {})
      @project = project
      @repo = repo
      @branch = branch

      # Provides an override list of languages. If not present, the downloader
      # will make an API call to fetch the list of languages for the project.
      @languages = options[:languages]
    end

    def each(&block)
      enum.each(&block)
    end

    private

    def enum
      if repo.upload_diffs?
        download_merging_diff
      else
        download_without_diff
      end
    end

    def download_merging_diff
      return to_enum(__method__) unless block_given?

      download_each do |head_resource, language_code, file_name|
        diff_point_resource = tx_config.resource(
          head_resource.original_resource_slug, repo.diff_point
        )

        source_diff = source_diff_hash(head_resource, diff_point_resource)
        head_content = transifex_download(head_resource, language_code)
        diff_point_content = transifex_download(diff_point_resource, language_code)
        contents = diff_point_content.merge(head_content, source_diff)

        yield file_name, contents.to_s(language_code)
      end
    end

    def source_diff_hash(head_resource, diff_point_resource)
      cache_diff(head_resource, diff_point_resource) do
        branch = repo.process_all_branches? ? branch : repo.branch
        head_contents = git_download(head_resource, branch)
        diff_point_contents = git_download(diff_point_resource, repo.diff_point)
        head_contents.diff_hash(diff_point_contents)
      end
    end

    def cache_diff(head_resource, diff_point_resource)
      key = "#{head_resource.resource_slug}|#{diff_point_resource.resource_slug}"
      if diff = diff_cache[key]
        diff
      else
        diff_cache[key] = yield
      end
    end

    def diff_cache
      @diff_cache ||= {}
    end

    def download_without_diff
      return to_enum(__method__) unless block_given?

      download_each do |resource, language_code, file_name|
        contents = transifex_download(resource, language_code)
        yield file_name, contents.to_s(language_code)
      end
    end

    def download_each
      each_resource do |resource|
        each_language do |language_code|
          file_name = file_name_for(resource, language_code)
          yield resource, language_code, file_name
        end
      end
    end

    def file_name_for(resource, language_code)
      resource.translation_file.sub('<lang>', language_code)
    end

    def transifex_download(resource, language)
      ResourceContents.from_string(
        resource, transifex_api.download(resource, language)
      )
    end

    def git_download(resource, branch)
      ResourceContents.from_string(
        resource, repo.api.download(repo.name, resource.source_file, branch)
      )
    end

    def transifex_api
      project.api
    end

    def each_resource
      return to_enum(__method__) unless block_given?

      ref = repo.process_all_branches? ? branch : nil

      raw_resources.each do |res|
        if resource = tx_config.resource(res['slug'], ref)
          yield(resource) if resource.resource_slug == res['slug']
        end
      end
    end

    def each_language
      return to_enum(__method__) unless block_given?

      raw_languages.each do |lang|
        yield lang['language_code']
      end
    end

    def raw_languages
      @languages ||= transifex_api.get_languages(project.name)
    end

    def raw_resources
      @raw_resources ||= transifex_api.get_resources(project.name)
    end

    def tx_config
      @tx_config ||= Txgh::Config::TxManager.tx_config(
        project, repo, repo.process_all_branches? ? branch : repo.branch
      )
    end
  end
end