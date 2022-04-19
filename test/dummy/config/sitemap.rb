# frozen_string_literal: true

require "folio/sitemap_generator"

SitemapGenerator::Sitemap.default_host = "http://#{Folio::Site.instance.domain}"
SitemapGenerator::Sitemap.sitemaps_path = "sitemaps"

SitemapGenerator::Sitemap.create do
  default_url_options[:only_path] = true

  includes_image_sitemap_scope(Folio::Page).published.find_each do |page|
    next unless page.class.public?

    add(
      page_path(page),
      changefreq: "monthly",
      priority: 0.5,
      images: page.image_sitemap
    )
  end
end
