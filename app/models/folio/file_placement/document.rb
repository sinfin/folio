# frozen_string_literal: true

class Folio::FilePlacement::Document < Folio::FilePlacement::Base
  folio_document_placement :document_placements,
                           has_many: true
end
