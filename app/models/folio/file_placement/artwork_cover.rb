# frozen_string_literal: true

class Folio::FilePlacement::ArtworkCover < Folio::FilePlacement::Base
  folio_image_placement :artwork_cover_placement,
                        has_many: false
end
