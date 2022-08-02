# frozen_string_literal: true

class PhoneInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options = nil)
    input_html_options[:class] ||= []
    input_html_options[:class] << "f-input f-input--phone"

    if options[:default_country_code]
      input_html_options["data-default-country-code"] = options[:default_country_code]
    end

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    @builder.text_field(attribute_name, merged_input_options)
  end
end
