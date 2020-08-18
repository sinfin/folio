# frozen_string_literal: true

class AdvancedRedactorInput < SimpleForm::Inputs::TextInput
  def input(wrapper_options = nil)
    input_html_options[:class] ||= []
    input_html_options[:class] << "folio-console-redactor-input "\
                                  "folio-console-redactor-input--advanced"
    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    @builder.text_area(attribute_name, merged_input_options)
  end
end
