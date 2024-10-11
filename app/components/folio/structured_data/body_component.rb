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
                                   current_site.title,
                                   current_site.env_aware_root_url)
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
      "name" => current_site.title
    }

    if current_site.structured_data_config.present? && current_site.structured_data_config[:icon_url].present?
      data["logo"] = {
        "@type" => "ImageObject",
        "url" => current_site.structured_data_config[:icon_url]
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
      "url" => current_site.env_aware_root_url,
      "name" => current_site.title,
      "publisher" => publisher_data
    }
  end

  def structured_data_hash_for_article
    if @record.published_authors.present?
      author_for_hash = @record.published_authors.first
      author_hash = {
        "@type" => "Person",
        "name" => author_for_hash.full_name,
        "url" => url_for([author_for_hash, only_path: false])
      }
    else
      author_hash = nil
    end

    {
      "@type" => "Article",
      "mainEntityOfPage" => {
        "@type" => "WebPage",
        "@id" => url_for([@record, only_path: false]),
      },
      "headline" => @record.title,
      "description" => @record.perex,
      "image" => @record.cover.present? ? [@record.cover.thumb(Folio::OG_IMAGE_DIMENSIONS).url] : nil,
      "datePublished" => @record.published_at_with_fallback.iso8601,
      "dateModified" => @record.try(:revised_at).present? ? @record.revised_at.iso8601 : nil,
      "keywords" => @record.try(:published_tags).present? ? @record.published_tags.map(&:title) : nil,
      "author" => author_hash,
      "publisher" => publisher_data
    }.compact
  end
end
