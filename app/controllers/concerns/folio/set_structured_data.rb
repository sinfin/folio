# frozen_string_literal: true

module Folio::SetStructuredData
  extend ActiveSupport::Concern

  included do
    helper_method :structured_data
  end

  def add_homepage_structured_data_breadcrumb
    add_structured_data_breadcrumb(current_site.title, current_site.env_aware_root_url)
  end

  def add_breadcrumb_on_rails(name, path = nil, options = {})
    add_structured_data_breadcrumb(name, path) unless path.nil? || options.delete(:exclude_from_structured_data)

    super(name, path, options)
  end
  alias add_breadcrumb add_breadcrumb_on_rails

  def set_structured_data_for_article(article)
    @structured_data_article = cache(cache_key_base + ["structured_data/article", article.id]) do
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

  private
    def structured_data
      data = [
        @structured_data_article,
        @structured_data_breadcrumbs,
      ].compact

      if @structured_data_article.nil?
        data << {
          "@type" => "WebSite",
          "url" => current_site.env_aware_root_url,
          "name" => current_site.title,
          "publisher" => publisher_data
        }
      end

      return if data.blank?

      {
        "@context" => "https://schema.org",
        "@graph" => data
      }
    end

    def add_structured_data_breadcrumb(name, url)
      @structured_data_breadcrumbs ||= {
        "@type" => "BreadcrumbList",
        "itemListElement" => []
      }
      @structured_data_breadcrumbs["itemListElement"] << {
        "@type" => "ListItem",
        "position" => @structured_data_breadcrumbs["itemListElement"].size + 1,
        "name" => name,
        "item" => url
      }
    end

    def publisher_data
      {
        "@type" => "Organization",
        "name" => current_site.title,
        "logo" => {
          "@type" => "ImageObject",
          "url" => "#{current_site.env_aware_root_url.chomp('/')}#{current_site.ui_config[:schema_icon_path]}",
        }
      }
    end
end
