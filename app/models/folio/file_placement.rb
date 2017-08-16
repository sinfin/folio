module Folio
  class FilePlacement < ApplicationRecord
    # Relations
    belongs_to :file, class_name: 'Folio::File'
    belongs_to :node, class_name: 'Folio::FileNode'
    # Scopes
    scope :with_image,   -> { joins(:file).where("folio_files.type = 'Folio::Image'") }
    scope :with_document,   -> { joins(:file).where("folio_files.type = 'Folio::Document'") }
  end
end
