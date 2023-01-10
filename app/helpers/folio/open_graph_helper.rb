# frozen_string_literal: true

module Folio::OpenGraphHelper
  def og_image
    return @og_image if @og_image.present?
    path = defined?(og_image_fallback) ? og_image_fallback : current_site.og_image_with_fallback
    image_url(path, host: request.base_url)
  rescue Sprockets::Rails::Helper::AssetNotFound
    nil
  end

  def og_image_width
    @og_image_width || 1200
  end

  def og_image_height
    @og_image_height || 630
  end

  def og_title
    @og_title || public_page_title
  end

  def og_description
    @og_description || public_page_description
  end

  def og_site_name
    current_site.domain
  end

  def og_url
    request.original_url.gsub("http://", "https://")
  end
end
