# frozen_string_literal: true

class ColorInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options = nil)
    input_html_options[:class] ||= []
    input_html_options[:class] << "f-c-color-input"
    input_html_options[:class] << "string"
    input_html_options[:autocomplete] = "off"

    input_html_options[:type] = "color"

    if options[:atom_setting]
      input_html_options[:class] << "f-c-js-atoms-placement-setting"
      input_html_options["data-atom-setting"] = options[:atom_setting]
    end

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    @builder.text_field(attribute_name, merged_input_options)
  end
end
