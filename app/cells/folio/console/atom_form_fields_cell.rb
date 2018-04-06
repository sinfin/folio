# frozen_string_literal: true

class Folio::Console::AtomFormFieldsCell < FolioCell
  include Folio::Console::ReactHelper

  def f
    model
  end

  def atom
    model.object
  end

  def supports_images?
    atom.class.images != :none
  end

  def atom_types_for_select
    for_select = []
    Folio::Atom.types.each do |type|
      if type.form
        for_select << [type.model_name.human,
                       type,
                       {
                         'data-console-form' => type.form,
                         'data-images' => type.images,
                       }]
      end
    end
    for_select
  end

  def content_field
    form = f.object.class::STRUCTURE[:content]
    active = %i[string redactor].include?(form)

    f.input :content,
      disabled: !active,
      wrapper_html: { hidden: !active },
      input_html: { class: 'folio-console-atom-textarea' }
  end

  def title_field
    form = f.object.class::STRUCTURE[:title]
    active = (form == :string)

    f.input :title,
      disabled: !active,
      wrapper_html: { hidden: !active }
  end

  def model_field
    selects = Folio::Atom.types.map do |type|
      models = type::STRUCTURE[:model]
      if models.present?
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
    atom.resource_for_select.map do |model|
      [
        model.to_label,
        model.id,
        { 'data-content': model.try(:to_content) }
      ]
    end
  end
end
