# frozen_string_literal: true

class Folio::FilePlacement::Cover < Folio::FilePlacement::Base
  include Folio::Sitemap::FilePlacement::Image

  folio_image_placement :cover_placement,
                        has_many: false
end
