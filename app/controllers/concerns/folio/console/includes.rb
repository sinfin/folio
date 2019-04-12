# frozen_string_literal: true

module Folio::Console::Includes
  extend ActiveSupport::Concern

  private

    def folio_console_collection_includes
      []
    end

    def folio_console_record_includes
      []
    end

    def folio_console_cover_includes
      [
        cover_placement: :file,
      ]
    end

    def folio_console_attachment_includes
      [
        cover_placement: :file,
        document_placement: :file,
        image_placements: :file,
        document_placements: :file,
      ]
    end

    def folio_console_atom_includes(klass = nil)
      (klass || @klass).reflections
                       .keys
                       .grep(/atoms/)
                       .map do |relation|
                         { relation => folio_console_attachment_includes }
                       end
    end
end
