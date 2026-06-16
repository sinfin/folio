# frozen_string_literal: true

class Folio::FilePlacement::SingleDocument < Folio::FilePlacement::Base
  folio_document_placement :document_placement,
                           has_many: false
end
