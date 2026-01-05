# frozen_string_literal: true

def create_test_tiptap_node(klass, *fill_attrs, **data_attrs)
  attrs = data_attrs

  fill_attrs.each do |field|
    attrs[field] = case field
                   when :cover
                     create(:folio_file_image)
                   when :video_cover
                     create(:folio_file_video)
                   when :images
                     create_list(:folio_file_image, 1)
                   when :document
                     create(:folio_file_document)
                   when :documents
                     create_list(:folio_file_document, 1)
                   else
                     field.to_s
    end
  end

  klass.new(attrs)
end
