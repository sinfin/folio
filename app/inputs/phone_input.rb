# frozen_string_literal: true

class PhoneInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options = nil)
    default_country_code = if options[:default_country_code]
      options[:default_country_code]
    elsif I18n.default_locale == :cs
      "cz"
    else
      ""
    end

    register_stimulus("f-input-form-group-phone",
                      values: { default_country_code:, bound: false },
                      wrapper: true)

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    @builder.text_field(attribute_name, merged_input_options)
  end
end
