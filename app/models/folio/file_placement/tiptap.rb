# frozen_string_literal: true

class Folio::FilePlacement::Tiptap < Folio::FilePlacement::Base
  folio_file_placement "Folio::File",
                       :tiptap_placements,
                       allow_embed: true,
                       has_many: true
end
