# frozen_string_literal: true

class Folio::StructuredData::BodyComponent < Folio::ApplicationComponent
  def initialize(record: nil, breadcrumbs: nil)
    @record = record
    @breadcrumbs = breadcrumbs
  end

  def structured_data
    return @structured_data if @structured_data.present?
    data = []

    data << main_structured_data if @record.present?
    data << breadcrumbs_structured_data if @breadcrumbs.any?

    return if data.blank?

    @structured_data = {
    "@context" => "https://schema.org",
    "@graph" => data
  }
  end

  def main_structured_data
    return set_structured_data_for_article(@record) if article_record?

    {
      "@type" => "WebSite",
      "url" => current_site.env_aware_root_url,
      "name" => current_site.title,
      "publisher" => publisher_data
    }
  end

  def breadcrumbs_structured_data
    breadcrumbs_data  ||= {
      "@type" => "BreadcrumbList",
      "itemListElement" => []
    }

    add_homepage_structured_data_breadcrumb(breadcrumbs_data)
    @breadcrumbs.each do |breadcrumb|
      add_structured_data_breadcrumb(breadcrumbs_data, breadcrumb.name, breadcrumb.path) unless breadcrumb.path.nil? ||
      breadcrumb.options.delete(:exclude_from_structured_data)
    end

    breadcrumbs_data
  end

  def add_homepage_structured_data_breadcrumb(data)
    add_structured_data_breadcrumb(data, current_site.title, current_site.env_aware_root_url)
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
    if current_site.ui_config[:schema_icon_path].present?
      data["logo"] = {
        "@type" => "ImageObject",
        "url" => "#{current_site.env_aware_root_url.chomp('/')}#{current_site.ui_config[:schema_icon_path]}"
    }
    end
    data
  end

  def article_record?
    @record.respond_to?(:perex) && @record.type.present? && @record.type.match?(/::Article(\z|::)/)
  end

  def set_structured_data_for_article(article)
    if article.published_authors.present?
      author_for_hash = article.published_authors.first
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
        "@id" => url_for([article, only_path: false]),
      },
      "headline" => article.title,
      "description" => article.perex,
      "image" => article.cover.present? ? [article.cover.thumb(Folio::OG_IMAGE_DIMENSIONS).url] : nil,
      "datePublished" => article.published_at_with_fallback.iso8601,
      "dateModified" => article.revised_at.present? ? article.revised_at.iso8601 : nil,
      "keywords" => article.published_tags.present? ? article.published_tags.map(&:title) : nil,
      "author" => author_hash,
      "publisher" => publisher_data
    }.compact
  end
end
