# frozen_string_literal: true

module Folio::Sitemap
  module Base
    extend ActiveSupport::Concern

    def image_sitemap(size = nil)
      placements = []

      if self.try(:cover_placement).present?
        placements << self.cover_placement
      end

      if self.try(:image_placements).present?
        placements += self.image_placements.to_a
      end

      if self.try(:atom_image_placements).present?
        placements += self.atom_image_placements
      end

      placements.uniq { |ip| ip.file_id }
                .filter_map { |ip| ip.to_sitemap(size) }
    end
  end

  module Image
    extend ActiveSupport::Concern

    def to_sitemap_loc(size = nil)
      # return thumbnail only if it's already generated
      hash = thumbnail_sizes[size || largest_thumb_key]
      hash[:url] if hash && hash[:uid] && !hash[:private]
    end

    def to_sitemap_title
      title || file_name
    end

    def to_sitemap_caption
      caption
    end
  end

  module FilePlacement
    module Image
      extend ActiveSupport::Concern

      def to_sitemap_title
        alt || file.to_sitemap_title
      end

      def to_sitemap_caption
        [placement_title, title, file.to_sitemap_caption].compact.join(" / ")
      end

      def to_sitemap(size = nil)
        loc = file.to_sitemap_loc(size)

        return if loc.nil?

        {
          loc:,
          title: to_sitemap_title,
          caption: to_sitemap_caption,
          geo_location: file.geo_location
        }.compact
      end
    end
  end
end
