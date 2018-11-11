# frozen_string_literal: true

namespace :folio do
  namespace :upgrade do
    task atom_document_placements: :environment do
      ids = []

      Folio::Atom.types.each do |type|
        if type::STRUCTURE[:document] && !type::STRUCTURE[:documents]
          type.includes(:document_placements).each do |atom|
            ids << atom.document_placements.pluck(:id)
          end
        end
      end

      Folio::FilePlacement::Document.where(id: ids)
                                    .update_all(type: 'Folio::FilePlacement::SingleDocument')
    end
  end
end
