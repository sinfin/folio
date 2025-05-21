# frozen_string_literal: true

class Folio::StructuredData::BodyComponent < Folio::ApplicationComponent
  def initialize(record: nil, breadcrumbs: nil)
    @record = record
    @breadcrumbs = breadcrumbs
  end

  def render?
    structured_data.present?
  end

  def structured_data
    return @structured_data if @structured_data.present?

    data = []

    data << structured_data_hash_for_record if @record.present?
    data << breadcrumbs_structured_data if @breadcrumbs.any?

    return if data.blank?

    @cache_key = if @record && Folio::Current.cache_key_base
      ["folio/structured_data/body_component", @record.class.table_name, @record.id, @record.updated_at] + Folio::Current.cache_key_base
    end

    @structured_data = {
      "@context" => "https://schema.org",
      "@graph" => data
    }
  end

  def breadcrumbs_structured_data
    breadcrumbs_data  ||= {
      "@type" => "BreadcrumbList",
      "itemListElement" => []
    }

    add_site_structured_data_breadcrumb(breadcrumbs_data)

    @breadcrumbs.each do |breadcrumb|
      next if breadcrumb.path.nil? || breadcrumb.options.delete(:exclude_from_structured_data)

      add_structured_data_breadcrumb(breadcrumbs_data,
                                     breadcrumb.name,
                                     breadcrumb.path)
    end

    breadcrumbs_data
  end

  def add_site_structured_data_breadcrumb(data)
    add_structured_data_breadcrumb(data,
                                   Folio::Current.site.title,
                                   Folio::Current.site.env_aware_root_url)
  end

  def add_structured_data_breadcrumb(data, name, url)
    data["itemListElement"] << {
      "@type" => "ListItem",
      "position" => data["itemListElement"].size + 1,
      "name" => name,
      "item" => url
    }
  end

  def publisher_data
    data = {
      "@type" => "Organization",
      "name" => Folio::Current.site.title
    }

    if Folio::Current.site.structured_data_config.present? && Folio::Current.site.structured_data_config[:icon_url].present?
      data["logo"] = {
        "@type" => "ImageObject",
        "url" => Folio::Current.site.structured_data_config[:icon_url]
      }
    end

    data
  end

  def article_record?
    @record.respond_to?(:perex) && @record.class.to_s.match?(/::Article(\z|::)/)
  end

  def structured_data_hash_for_record
    return structured_data_hash_for_article if article_record?

    {
      "@type" => "WebSite",
      "url" => Folio::Current.site.env_aware_root_url,
      "name" => Folio::Current.site.title,
      "publisher" => publisher_data
    }
  end

  def structured_data_hash_for_article_author_from(name:, url:)
    {
      "@type" => "Person",
      "name" => name,
      "url" => url,
    }
  end

  def structured_data_hash_for_article_author
    authors_ary = @record.try(:cache_aware_published_authors) || @record.published_authors

    if authors_ary.present?
      author_for_hash = authors_ary.first
      structured_data_hash_for_article_author_from(name: author_for_hash.full_name,
                                                   url: url_for([author_for_hash, only_path: false]))

    else
      nil
    end
  end

  def structured_data_hash_for_article
    tags_ary = @record.try(:cache_aware_published_tags) || @record.try(:published_tags)

    cover = @record.try(:cache_aware_cover) || @record.cover

    {
      "@type" => @record.try(:structured_data_type) || "Article",
      "mainEntityOfPage" => {
        "@type" => "WebPage",
        "@id" => url_for([@record, only_path: false]),
      },
      "headline" => @record.title,
      "description" => @record.perex,
      "image" => cover.present? ? [cover.thumb(record_cover_thumb_size).url] : nil,
      "datePublished" => @record.published_at_with_fallback.iso8601,
      "dateModified" => @record.try(:revised_at).present? ? @record.revised_at.iso8601 : nil,
      "keywords" => tags_ary.present? ? tags_ary.map(&:title) : nil,
      "author" => structured_data_hash_for_article_author,
      "publisher" => publisher_data
    }.compact
  end

  private
    def record_cover_thumb_size
      @record.try(:structured_data_cover_thumb_size) || Folio::OG_IMAGE_DIMENSIONS
    end

    def record_cover_thumb
      cover = @record.try(:cache_aware_cover) || @record.cover
      cover.present? ? cover.thumb(record_cover_thumb_size) : nil
    end
end
