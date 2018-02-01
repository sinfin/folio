# frozen_string_literal: true

module Folio
  module Console::ReactHelper
    def react_images(selected_placements = nil)
      react_files('Folio::Image', selected_placements.try(:with_image))
    end

    def react_documents(selected_placements = nil)
      react_files('Folio::Document', selected_placements.try(:with_document))
    end

    def react_files(type, selected_placements)
      if selected_placements.present?
        placements = selected_placements.ordered.map do |fp|
          { id: fp.id, file_id: fp.file.id }
        end.to_json
      else
        placements = nil
      end

      content_tag(:div, nil,
        'class': 'folio-react-wrap',
        'data-selected': placements,
        'data-file-type': type,
        'data-mode': 'multi-select',
      )
    end
  end
end
