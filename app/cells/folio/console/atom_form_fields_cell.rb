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

  def atom_types
    Folio::Atom.types
  end

  def atom_types_for_select
    atom_types.map do |type|
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
      hint: render(:content_hint).html_safe,
      wrapper_html: {
        hidden: !active,
        class: 'folio-console-atom-content',
      },
      input_html: {
        class: 'folio-console-atom-textarea',
        placeholder: Folio::Atom::Base.human_attribute_name(:content),
      }
  end

  def title_field
    title = structure[:title]
    active = (title == :string)

    f.input :title,
      disabled: !active,
      hint: render(:title_hint).html_safe,
      input_html: {
        placeholder: Folio::Atom::Base.human_attribute_name(:title),
      },
      wrapper_html: {
        hidden: !active,
        class: 'folio-console-atom-title',
      }
  end

  def perex_field
    perex = structure[:perex]
    active = (perex == :string)

    f.input :perex,
      disabled: !active,
      hint: render(:perex_hint).html_safe,
      input_html: {
        placeholder: Folio::Atom::Base.human_attribute_name(:perex),
      },
      wrapper_html: {
        hidden: !active,
        class: 'folio-console-atom-perex',
      }
  end

  def model_field
    selects = atom_types.map do |type|
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
