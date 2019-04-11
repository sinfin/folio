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

      if size.nil?
        image_placement_variants = []

        placements.each do |ip|
          ip.file.thumbnail_sizes.keys.each do |size_key|
            image_placement_variants << ip.to_sitemap(size_key)
          end
        end

        image_placement_variants.uniq
      else
        placements.uniq.collect { |ip| ip.to_sitemap(size) }
      end
    end
  end

  module Image
    extend ActiveSupport::Concern

    def to_sitemap_title
      self.title
    end

    def to_sitemap_caption
      self.caption
    end
  end

  module FilePlacement
    module Image
      extend ActiveSupport::Concern

      def to_sitemap_loc(size)
        self.file.file.thumb(size, immediate: true).url
      end

      def to_sitemap_title
        self.alt || self.file.to_sitemap_title
      end

      def to_sitemap_caption
        self.title || self.file.to_sitemap_caption
      end

      def to_sitemap(size)
        {
          loc: self.to_sitemap_loc(size),
          title: self.to_sitemap_title,
          caption: self.to_sitemap_caption,
          geo_location: self.file.geo_location
        }
      end
    end
  end
end
