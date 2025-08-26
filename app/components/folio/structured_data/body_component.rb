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
    data << structured_data_hash_for_video_cover if @record.present?
    data << breadcrumbs_structured_data if @breadcrumbs.any?

    return if data.blank?

    data = data.compact

    @cache_key = if @record && Folio::Current.cache_key_base
      [
        "folio/structured_data/body_component",
        @record.class.table_name,
        @record.id,
        @record.updated_at,
      ] + Folio::Current.cache_key_base
    end

    @structured_data = {
      "@context" => "https://schema.org",
      "@graph" => data,
    }
  end

  def breadcrumbs_structured_data
    breadcrumbs_data ||= {
      "@type" => "BreadcrumbList",
      "itemListElement" => [],
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
      "item" => url,
    }
  end

  def publisher_data
    data = {
      "@type" => "Organization",
      "name" => Folio::Current.site.title,
    }

    if Folio::Current.site.structured_data_config.present? && Folio::Current.site.structured_data_config[:icon_url].present?
      data["logo"] = {
        "@type" => "ImageObject",
        "url" => Folio::Current.site.structured_data_config[:icon_url],
        "description" => Folio::Current.site.title,
      }
    end

    data
  end

  def article_record?
    @record.respond_to?(:perex) && @record.class.to_s.match?(/::Article(\z|::)/)
  end

  def author_record?
    @record.respond_to?(:last_name) && @record.class.to_s.match?(/::Author(\z|::)/)
  end

  def structured_data_hash_for_record
    return structured_data_hash_for_article if article_record?
    return structured_data_hash_for_author if author_record?

    {
      "@type" => "WebSite",
      "url" => Folio::Current.site.env_aware_root_url,
      "name" => Folio::Current.site.title,
      "publisher" => publisher_data,
    }
  end

  def structured_data_hash_for_article_author_from(name: nil, url: nil, cover: nil)
    {
      "@type" => "Person",
      "name" => name,
      "url" => url,
      "image" => cover,
    }.compact
  end

  def structured_data_hash_for_video_cover
    video = @record.try(:cache_aware_video_cover) || @record.try(:video_cover)
    return unless video.present?

    {
      "@type" => "VideoObject",
      "name" => @record.title,
      "description" => video.description || @record.perex,
      "thumbnailUrl" => video.remote_cover_url,
      "uploadDate" => video.created_at.iso8601,
      "contentUrl" => Folio::S3.cdn_url_rewrite(video.file.remote_url),
      "duration" => ActiveSupport::Duration.build(video.file_track_duration).iso8601,
    }.compact
  end

  def structured_data_hash_for_article_author
    authors_ary = @record.try(:cache_aware_published_authors) || @record.published_authors

    return unless authors_ary.present?

    authors_ary.map do |author_for_hash|
      structured_data_hash_for_article_author_from(name: author_for_hash.full_name,
                                                   url: url_for([author_for_hash, only_path: false]))
    end
  end

  def structured_data_hash_for_article
    tags_ary = @record.try(:cache_aware_published_tags) || @record.try(:published_tags)

    cover_hash = structured_data_hash_for_cover(record_cover_thumb)

    {
      "@type" => @record.try(:structured_data_type) || "Article",
      "url" => url_for([@record, only_path: false]),
      "name" => Folio::Current.site.title,
      "mainEntityOfPage" => {
        "@type" => "WebPage",
        "@id" => url_for([@record, only_path: false]),
      },
      "headline" => @record.title,
      "description" => @record.perex,
      "image" => cover_hash.presence,
      "datePublished" => @record.published_at_with_fallback.iso8601,
      "dateModified" => @record.try(:revised_at).present? ? @record.revised_at.iso8601 : nil,
      "keywords" => tags_ary.present? ? tags_ary.map(&:title) : nil,
      "author" => structured_data_hash_for_article_author,
      "publisher" => publisher_data,
    }.compact
  end

  def structured_data_hash_for_author
    cover_hash = structured_data_hash_for_cover(record_cover_thumb)
    social_links = @record.try(:social_links) || {}

    if @record.email.present?
      email_text = "mailto:#{@record.email}"
    end

    {
      "@type" => "Person",
      "url" => url_for([@record, only_path: false]),
      "name" => "#{@record.full_name} - #{Folio::Current.site.title}",
      "email" => email_text,
      "jobTitle" => @record.try(:job_label).presence,
      "sameAs" => social_links["twitter"].presence,
      "image" => cover_hash.presence,
    }.compact
  end

  def structured_data_hash_for_cover(cover)
    return unless cover.present?

    {
      "@type" => "ImageObject",
      "url" => cover.url,
      "creditText" => cover.try(:author),
      "width" => cover.width,
      "height" => cover.height,
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
