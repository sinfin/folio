# frozen_string_literal: true

module Folio
  module Console::ReactHelper
    def react_images(selected_placements = nil,
                     attachmentable: 'node',
                     type: :image_placements)
      react_files('Folio::Image',
                  selected_placements,
                  attachmentable: attachmentable,
                  type: type)
    end

    def react_documents(selected_placements = nil,
                        attachmentable: 'node',
                        type: :document_placements)
      react_files('Folio::Document',
                  selected_placements,
                  attachmentable: attachmentable,
                  type: type)
    end

    def react_picker(f, placement_key, file_type: 'Folio::Image', title: nil)
      raw cell('folio/console/react_picker', f, placement_key: placement_key,
                                                title: title,
                                                file_type: file_type)
    end

    def react_modal_for(file_type)
      if ['new', 'edit', 'create', 'update'].include?(action_name)
        content_tag(:div, nil,
          'class': 'folio-react-wrap',
          'data-file-type': file_type,
          'data-mode': 'modal-select',
        )
      end
    end

    private

      def react_files(file_type, selected_placements, attachmentable:, type:)
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
          'data-file-type': file_type,
          'data-mode': 'multi-select',
          'data-attachmentable': attachmentable,
          'data-placement-type': type,
        )
      end
  end
end
