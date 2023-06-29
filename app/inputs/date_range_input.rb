# frozen_string_literal: true

class DateRangeInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options = nil)
    register_stimulus("f-input-date-range",
                      options[:max_date] ? { max_date: I18n.l(options[:max_date].to_date, format: :console_short) } : {})

    input_html_options["autocomplete"] = "off"

    register_atom_settings

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    @builder.text_field(attribute_name, merged_input_options)
  end
end
