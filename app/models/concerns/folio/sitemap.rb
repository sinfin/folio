# frozen_string_literal: true

module Folio::Sitemap
  module Base
    extend ActiveSupport::Concern

    def image_sitemap(size=nil)
      image_placements = []
      image_placements << self.cover_placement if self.respond_to?(:cover_placement)
      image_placements << self.atoms_image_placements  if self.respond_to?(:atoms_image_placements)
      image_placements << self.image_placements if self.respond_to?(:image_placements)
      image_placements.flatten!.compact!

      unless size.nil?
        return image_placements.collect { |ip| ip.to_sitemap(size) }
      else
        image_placement_variants = []
        image_placements.each do |ip|
          ip.file.thumbnail_sizes_keys.each do |size_key|
            image_placement_variants << ip.to_sitemap(size_key)
          end
        end
        return image_placement_variants
      end
    end
  end

  module Image
    extend ActiveSupport::Concern

    def sitemap_title
      nil # TODO: self.alt
    end

    def sitemap_caption
      nil # TODO: self.caption
    end
  end

  module FilePlacement
    module Image
      extend ActiveSupport::Concern

      def sitemap_loc(size=nil)
        self.file.file.thumb(size, immediate: true).url
      end

      def sitemap_title
        self.alt || self.file.sitemap_title
      end

      def sitemap_caption
        self.title || self.file.sitemap_caption
      end

      def to_sitemap(size=nil)
        {
          loc: self.sitemap_loc(size=nil),
          title: self.sitemap_title,
          caption: self.sitemap_caption
          # TODO: geo_location: file.todo_loc
          # Geografické umístění obrázku. Příklad: <image:geo_location>Limerick, Irsko</image:geo_location>.
        }
      end
    end
  end
end
