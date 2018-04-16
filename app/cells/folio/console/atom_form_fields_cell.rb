# frozen_string_literal: true

class Folio::Console::AtomFormFieldsCell < FolioCell
  include Folio::Console::ReactHelper
  include Folio::Console::StiHelper

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
    Folio::Atom.types.map do |type|
      next if type == Folio::Atom::Base
      [
        type.model_name.human,
        type,
        {
          'data-atom-structure' => type.structure_as_json,
        }
      ]
    end.compact.sort_by(&:first)
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
        became = f.object.becomes(type)
        f.input :model,
          collection: atom_model_collection_for_select(became),
          selected: sti_record_select_value(became, :model),
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
    klass = atom.class
    show_model_names = klass::STRUCTURE[:model].size > 1

    klass::STRUCTURE[:model].map do |model_class|
      sti_records_for_select(klass.scoped_model_resource(model_class),
                             show_model_names: show_model_names,
                             add_content: true)

    end.flatten(1)
  end
end
