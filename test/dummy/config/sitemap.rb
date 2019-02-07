# frozen_string_literal: true

require 'rubygems'
require 'sitemap_generator'

SitemapGenerator::Sitemap.default_host = Folio::Site.first.url
SitemapGenerator::Sitemap.create do
  Folio::Page.published.each do |page|
    add Folio::Engine.app.url_helpers.page_url(page), changefreq: 'daily', priority: 0.9
  end
end
