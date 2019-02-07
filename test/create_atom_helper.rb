# frozen_string_literal: true

def create_atom(klass = Folio::Atom::Base,
                *fill_attrs,
                position: nil,
                placement: nil,
                title: nil,
                perex: nil,
                content: nil,
                model: nil,
                cover: nil,
                images: nil,
                document: nil,
                documents: nil)

  attrs = {
    type: klass.to_s,
    position: position,
    placement: placement || create(:folio_page),
    title: title ||
           (fill_attrs.include?(:title) ? 'Title' : nil),
    perex: perex ||
           (fill_attrs.include?(:perex) ? 'Perex' : nil),
    content: content ||
             (fill_attrs.include?(:content) ? 'Content' : nil),
    model: model ||
           (fill_attrs.include?(:model) ? create(:folio_page) : nil),
    cover: cover ||
           (fill_attrs.include?(:cover) ? create(:folio_image) : nil),
    images: images ||
            (fill_attrs.include?(:images) ? create_list(:folio_image, 1) : nil),
    document: document ||
              (fill_attrs.include?(:document) ? create(:folio_document) : nil),
    documents: documents ||
               (fill_attrs.include?(:documents) ? create_list(:folio_document, 1) : nil),
  }.compact

  if ::Rails.application.config.folio_using_traco
    ::Folio::Atom.text_fields.each do |field|
      locales = I18n.available_locales.join('|')
      raw_field = field.to_s.gsub(/_(#{locales})/, '').to_sym
      attrs[field] = attrs[raw_field]
    end
    attrs.delete :title
    attrs.delete :perex
    attrs.delete :content
  end

  klass.create!(attrs)
end
