module Txgh
  class TxResource
    attr_reader :project_slug, :resource_slug, :type, :source_lang
    attr_reader :source_file, :translation_file

    alias_method :original_resource_slug, :resource_slug

    def initialize(project_slug, resource_slug, type, source_lang, source_file,
        lang_map, translation_file)
      @project_slug = project_slug
      @resource_slug = resource_slug
      @type = type
      @source_lang = source_lang
      @source_file = source_file
      @lang_map = {}

      if lang_map
        result = {}
        lang_map.split(',').each do |m|
          key_value = m.split(':', 2)
          result[key_value[0].strip] = key_value[1].strip
        end

        @lang_map = result
      end

      @translation_file = translation_file
    end

    def lang_map(tx_lang)
      @lang_map.fetch(tx_lang, tx_lang)
    end

    def translation_path(language)
      translation_file.gsub('<lang>', language)
    end

    def slugs
      [project_slug, resource_slug]
    end

    def to_h
      {
        project_slug: project_slug,
        resource_slug: resource_slug,
        type: type,
        source_lang: source_lang,
        source_file: source_file,
        translation_file: translation_file
      }
    end

    def to_api_h
      {
        'slug' => resource_slug,
        'i18n_type' => type,
        'source_language_code' => source_lang,
        'name' => translation_file
      }
    end

    def branch
      nil
    end

    def has_branch?
      false
    end
  end
end
