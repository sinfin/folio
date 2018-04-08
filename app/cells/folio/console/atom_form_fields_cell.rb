# frozen_string_literal: true

class Folio::Console::AtomFormFieldsCell < FolioCell
  include Folio::Console::ReactHelper

  def f
    model
  end

  def atom
    model.object
  end

  def structure
    atom.class::STRUCTURE
  end

  def atom_types_for_select
    for_select = []
    Folio::Atom.types.each do |type|
      unless type == Folio::Atom::Base
        for_select << [type.model_name.human,
                       type,
                       {
                         'data-atom-structure' => type.structure_as_json,
                       }]
      end
    end
    for_select
  end

  def content_field
    form = structure[:content]
    active = %i[string redactor].include?(form)

    f.input :content,
      disabled: !active,
      wrapper_html: {
        hidden: !active,
        class: 'folio-console-atom-content',
      },
      input_html: { class: 'folio-console-atom-textarea' }
  end

  def title_field
    title = structure[:title]
    active = (title == :string)

    f.input :title,
      disabled: !active,
      wrapper_html: {
        hidden: !active,
        class: 'folio-console-atom-title',
      }
  end

  def model_field
    selects = Folio::Atom.types.map do |type|
      m = type::STRUCTURE[:model]
      if m.present?
        active = (type == f.object.class)
        f.association :model,
          collection: atom_model_collection_for_select(f.object.becomes(type)),
          include_blank: false,
          disabled: !active,
          wrapper_html: { hidden: !active },
          input_html: {
            class: 'folio-console-atom-model-select',
            data: { class: type.to_s }
          }
      end
    end.compact
    selects.join('')
  end

  def atom_model_collection_for_select(atom)
    atom.class.resource_for_select.map do |model|
      [
        model.try(:to_label) || model.try(:title) || model.model_name.human,
        model.id,
        { 'data-content': model.try(:to_content) }
      ]
    end
  end
end
