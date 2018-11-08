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
    end.compact.sort_by { |name, _type, _data| I18n.transliterate(name) }
  end

  def title_field
    common_fields(:title)
  end

  def perex_field
    common_fields(:perex, textarea: true)
  end

  def content_field
    common_fields(:content, textarea: true)
  end

  def common_fields(attr, textarea: true)
    if Folio::Atom.translations.present?
      fields = Folio::Atom.translations.map do |locale|
        field = common_field(attr, textarea: textarea, flag: locale)
        "<div class=\"col-md\">#{field}</div>"
      end

      "<div class=\"row\">#{fields.join('')}</div>"
    else
      common_field(attr, textarea: textarea)
    end
  end

  def common_field(attr, textarea: false, flag: nil)
    active = %i[string redactor].include?(structure[attr])
    hint = "#{attr}_hint".to_sym
    input_name = flag ? [attr, flag].join('_') : attr

    f.input input_name,
      disabled: !active,
      hint: render(hint).html_safe,
      input_html: {
        placeholder: Folio::Atom::Base.human_attribute_name(attr),
        class: textarea ? 'folio-console-atom-textarea' : nil,
      },
      flag: flag,
      wrapper: flag ? :with_flag : nil,
      wrapper_html: {
        hidden: !active,
        class: "folio-console-atom-#{attr}",
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
          include_blank: true,
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

  def placeholders
    base_placeholders = Folio::Atom::Base.form_placeholders

    atom_types.map do |type|
      [type.to_s, base_placeholders.merge(type.form_placeholders)]
    end.to_h.to_json
  end
end
