# frozen_string_literal: true

class Folio::FilePlacement::Image < Folio::FilePlacement::Base
  include Folio::Sitemap::FilePlacement::Image

  folio_image_placement :image_placements,
                        has_many: true
end
