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

    def react_images_modal
      react_modal_for 'Folio::Image'
    end

    def react_documents_modal
      react_modal_for 'Folio::Document'
    end

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

    def react_image_select(f, multi: false, cover: false, key: nil, title: nil)
      raw cell('folio/console/react_image_select', f, multi: multi,
                                                      cover: cover,
                                                      key: key,
                                                      title: title)
    end

    def react_cover_select(f, key: nil, title: nil)
      raw cell('folio/console/react_image_select', f, multi: false,
                                                      cover: true,
                                                      key: key,
                                                      title: title)
    end

    def react_images_select(f, key: nil, title: nil)
      raw cell('folio/console/react_image_select', f, multi: true,
                                                      cover: false,
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

      def react_modal_for(file_type)
        if ['new', 'edit', 'create', 'update'].include?(action_name)
          content_tag(:div, nil,
            'class': 'folio-react-wrap',
            'data-file-type': file_type,
            'data-mode': 'modal-select',
          )
        end
      end
  end
end
