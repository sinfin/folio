# frozen_string_literal: true

class Folio::FilePlacement::ImageOrEmbed < Folio::FilePlacement::Base
  include Folio::Sitemap::FilePlacement::Image

  folio_image_placement :image_or_embed_placements,
                        allow_embed: true,
                        has_many: true
end
