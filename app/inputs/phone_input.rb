# frozen_string_literal: true

class PhoneInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options = nil)
    input_html_options[:class] ||= []
    input_html_options[:class] << "f-input f-input--phone"

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    @builder.text_field(attribute_name, merged_input_options)
  end
end
