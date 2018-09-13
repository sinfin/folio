# frozen_string_literal: true

module Folio
  module OpenGraphHelper
    def og_image
      begin
        return @og_image if @og_image.present?
        path = defined?(og_image_fallback) ? og_image_fallback : '/fb-share.png'
        image_url(path, host: request.base_url)
      rescue Sprockets::Rails::Helper::AssetNotFound
        nil
      end
    end

    def og_image_width
      @og_image_width || 1200
    end

    def og_image_height
      @og_image_height || 630
    end

    def og_site_name
      Site.instance.domain
    end

    def og_url
      request.original_url.gsub('http://', 'https://')
    end
  end
end
