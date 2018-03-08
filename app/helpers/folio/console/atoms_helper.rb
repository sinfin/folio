# frozen_string_literal: true

module Folio
  module Console::AtomsHelper
    def atom_types_for_select
      for_select = []
      ::Folio::Atom.types.each do |type|
        if type.form
          for_select << [type.model_name.human,
                         type,
                         { 'data-form' => type.form }]
        end
      end
      for_select
    end

    def atom_model_field(f)
      selects = ::Folio::Atom.types.map do |type|
        if type::ALLOWED_MODEL_TYPE.present?
          active = type == f.object.class
          f.association :model,
            collection: atom_model_collection_for_select(f.object.becomes(type)),
            include_blank: false,
            disabled: !active,
            wrapper_html: {
              style: ('display:none' if !active)
            },
            input_html: {
              class: 'atom-model-select',
              data: { class: type.to_s }
            }
        end
      end.compact
      selects.join('').html_safe
    end

    def atom_content_field(f)
      active = %i[string redactor].include? f.object.class.form
      f.input :content,
        wrapper_html: {
          class: 'atom-content',
          style: ('display:none' if !active)
        },
        input_html: {
          class: ('redactor' if f.object.class.form == :redactor)
        }
    end

    def atom_model_collection_for_select(atom)
      atom.resource_for_select.map do |model|
        [
          model.to_label,
          model.id,
          { 'data-content': model.try(:to_content) }
        ]
      end
    end
  end
end
