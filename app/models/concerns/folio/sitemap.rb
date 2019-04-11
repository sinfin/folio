# frozen_string_literal: true

module Folio::Sitemap
  module Base
    extend ActiveSupport::Concern

    def image_sitemap(size = nil)
      image_placements = []

      if self.try(:cover_placement).present?
        image_placements << self.cover_placement
      end

      if self.try(:atom_image_placements).present?
        image_placements += self.atom_image_placements
      end

      if self.try(:image_placements).present?
        image_placements += self.image_placements.to_a
      end

      unless size.nil?
        return image_placements.uniq.collect { |ip| ip.to_sitemap(size) }
      else
        image_placement_variants = []
        image_placements.each do |ip|
          ip.file.thumbnail_sizes_keys.each do |size_key|
            image_placement_variants << ip.to_sitemap(size_key)
          end
        end
        return image_placement_variants.uniq
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

      def to_sitemap_loc(size = nil)
        self.file.file.thumb(size, immediate: true).url
      end

      def to_sitemap_title
        self.alt || self.file.to_sitemap_title
      end

      def to_sitemap_caption
        self.title || self.file.to_sitemap_caption
      end

      def to_sitemap(size = nil)
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
