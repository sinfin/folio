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

    def react_modal_for(file_type, single: true)
      if ['new', 'edit', 'create', 'update'].include?(action_name)
        mode = single ? 'modal-single-select' : 'modal-multi-select'

        content_tag(:div, nil,
          'class': 'folio-react-wrap',
          'data-file-type': file_type,
          'data-mode': mode,
        )
      end
    end

    private

      def react_files(file_type, selected_placements, attachmentable:, type:)
        if selected_placements.present?
          placements = selected_placements.ordered.map do |fp|
            {
              id: fp.id,
              file_id: fp.file.id,
              alt: fp.alt,
              title: fp.title,
              file: Folio::FileSerializer.new(fp.file, root: false).serializable_hash,
            }
          end.to_json
        else
          placements = nil
        end

        content_tag(:div, nil,
          'class': 'folio-react-wrap',
          'data-original-placements': placements,
          'data-file-type': file_type,
          'data-mode': 'multi-select',
          'data-attachmentable': attachmentable,
          'data-placement-type': type,
        )
      end
  end
end
