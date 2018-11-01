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
      react_modal_for 'Folio::Image', attachmentable: attachmentable
    end

    def react_documents_modal(attachmentable: 'node')
      react_modal_for 'Folio::Document', attachmentable: attachmentable
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

    def react_image_select(f, multi: false, cover: false, key: nil, title: nil)
      raw cell('folio/console/react_image_select', f, multi: multi,
                                                      cover: cover,
                                                      key: key,
                                                      title: title)
    end

    def react_document_select(f, multi: false, key: nil, title: nil)
      raw cell('folio/console/react_document_select', f, multi: multi,
                                                         key: key,
                                                         title: title)
    end

    def react_has_one_document_select(f, key: nil, title: nil)
      raw cell('folio/console/react_has_one_document_select', f, key: key,
                                                                 title: title)
    end

    private

      def react_modal_for(file_type, attachmentable: 'node')
        if ['new', 'edit', 'create', 'update'].include?(action_name)
          content_tag(:div, nil,
            'class': 'folio-react-wrap',
            'data-file-type': file_type,
            'data-mode': 'modal-select',
            'data-attachmentable': attachmentable,
          )
        end
      end
  end
end
