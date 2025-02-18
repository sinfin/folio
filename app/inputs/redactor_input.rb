# frozen_string_literal: true

class RedactorInput < SimpleForm::Inputs::TextInput
  def input(wrapper_options = nil)
    register_stimulus("f-input-redactor", wrapper: true)
    register_atom_settings

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    @builder.text_area(attribute_name, merged_input_options)
  end
end
