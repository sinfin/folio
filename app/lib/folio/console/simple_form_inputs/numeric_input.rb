# frozen_string_literal: true

SimpleForm::Inputs::NumericInput.class_eval do
  def input(wrapper_options = nil)
    input_html_classes.unshift('numeric')

    if html5?
      input_html_options[:type] ||= 'number'
      input_html_options[:step] ||= integer? ? 1 : 'any'
    end

    if options[:numeral]
      input_html_classes << 'folio-console-string-input--numeral'
    end

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    @builder.text_field(attribute_name, merged_input_options)
  end
end
