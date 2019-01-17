# frozen_string_literal: true

require 'rubygems'
require 'sitemap_generator'

SitemapGenerator::Sitemap.default_host = Folio::Site.first.url
SitemapGenerator::Sitemap.create do
  Folio::Node.published.each do |node|
    case node.type
    when 'Folio::Page'
      add Folio::Engine.app.url_helpers.page_url(node), changefreq: 'daily', priority: 0.9
    when 'Folio::Category'
      add Folio::Engine.app.url_helpers.category_url(node), changefreq: 'monthly', priority: 0.7
    end
  end
end
