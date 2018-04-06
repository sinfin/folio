# frozen_string_literal: true

module Folio
  module Console::ReactHelper
    def react_images(selected_placements = nil, attachmentable: nil)
      react_files('Folio::Image',
                  selected_placements.try(:with_image),
                  attachmentable: attachmentable)
    end

    def react_documents(selected_placements = nil, attachmentable: nil)
      react_files('Folio::Document',
                  selected_placements.try(:with_document),
                  attachmentable: attachmentable)
    end

    def react_images_modal(attachmentable: 'node')
      if ['new', 'edit', 'create', 'update'].include?(action_name)
        content_tag(:div, nil,
          'class': 'folio-react-wrap',
          'data-file-type': 'Folio::Image',
          'data-mode': 'modal-select',
          'data-attachmentable': attachmentable,
        )
      end
    end

    def react_files(type, selected_placements, attachmentable: 'node')
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
        'data-attachmentable': attachmentable,
      )
    end

    def react_image_select(f, multi: false, cover: false)
      raw cell('folio/console/react_image_select', f, multi: multi,
                                                      cover: cover)
    end
  end
end
