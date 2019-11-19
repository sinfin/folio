# frozen_string_literal: true

SimpleForm::Inputs::CollectionSelectInput.class_eval do
  def input(wrapper_options = nil)
    label_method, value_method = detect_collection_methods

    iho = input_html_options || {}

    if options[:remote]
      iho[:class] = [iho[:class], 'f-c-collection-remote-select-input'].flatten
      iho['data-autocomplete-url'] = options[:remote]
    end

    merged_input_options = merge_wrapper_options(iho, wrapper_options)

    @builder.collection_select(
      attribute_name, collection, value_method, label_method,
      input_options, merged_input_options
    )
  end
end
