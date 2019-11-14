# frozen_string_literal: true

def create_atom(klass = Folio::Atom::Text, *fill_attrs, **data_attrs)
  attrs = data_attrs.merge(type: klass.to_s)
  attrs[:placement] ||= create(:folio_page)

  fill_attrs.each do |field|
    attrs[field] = case field
                   when :cover
                     create(:folio_image)
                   when :images
                     create_list(:folio_image, 1)
                   when :document
                     create(:folio_document)
                   when :documents
                     create_list(:folio_document, 1)
                   else
                     field.to_s
    end
  end

  klass.create!(attrs)
end
