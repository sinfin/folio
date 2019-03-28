# frozen_string_literal: true

require 'rubygems'
require 'sitemap_generator'

SitemapGenerator::Sitemap.default_host = "http://#{Folio::Site.instance.domain}"
SitemapGenerator::Sitemap.sitemaps_path = 'sitemaps'

SitemapGenerator::Sitemap.create do
  Folio::Page.published.each do |page|
    I18n.locale = page.locale unless page.locale.blank?

    add(
      page_path(page),
      lastmod: page.updated_at,
      changefreq: 'monthly',
      priority: 0.5,
      images: page.image_sitemap
    )
  end

  # TODO: Uncomment a search engine ping method within a site generator
  # for multiple site configuration
  # SitemapGenerator::Sitemap.ping_search_engines
end
