module Folio
  class FilePlacement < ApplicationRecord
    # Relations
    belongs_to :file, class_name: 'Folio::File'
    belongs_to :node, class_name: 'Folio::FileNode'
  end
end
