# frozen_string_literal: true

class AutocompleteInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options = nil)
    input_html_options[:class] ||= []
    input_html_options[:class] << 'folio-console-autocomplete-input'

    input_html_options['data-autocomplete'] = options[:collection].to_json

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    @builder.text_field(attribute_name, merged_input_options)
  end
end
