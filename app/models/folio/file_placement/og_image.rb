# frozen_string_literal: true

class Folio::FilePlacement::OgImage < Folio::FilePlacement::Base
  folio_image_placement :og_image_placement,
                        has_many: false
end
