# frozen_string_literal: true

module Folio::Sitemap
  module Base
    extend ActiveSupport::Concern

    def image_sitemap
      image_placements = []
      image_placements << self.cover_placement if self.respond_to?(:cover_placement)
      image_placements << self.atoms_image_placements  if self.respond_to?(:atoms_image_placements)
      image_placements << self.image_placements if self.respond_to?(:image_placements)
      image_placements.flatten!.compact!

      image_placements.collect { |ip| ip.to_sitemap }
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

      def sitemap_loc
        self.file.thumb('1000x1000').url
      end

      def sitemap_title
        self.alt || self.file.sitemap_title
      end

      def sitemap_caption
        self.title || self.file.sitemap_caption
      end

      def to_sitemap
        {
          loc: self.sitemap_loc,
          title: self.sitemap_title,
          caption: self.sitemap_caption
          # TODO: geo_location: file.todo_loc
          # Geografické umístění obrázku. Příklad: <image:geo_location>Limerick, Irsko</image:geo_location>.
        }
      end
    end
  end
end
