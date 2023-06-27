# frozen_string_literal: true

class DateRangeInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options = nil)
    register_stimulus("f-input-date-range")
    input_html_options["data-action"] = "f-input-date-range#onInput"

    input_html_options["autocomplete"] = "off"

    register_atom_settings

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    @builder.text_field(attribute_name, merged_input_options)
  end
end
