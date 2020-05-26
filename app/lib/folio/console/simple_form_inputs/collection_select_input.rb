# frozen_string_literal: true

SimpleForm::Inputs::CollectionSelectInput.class_eval do
  def input(wrapper_options = nil)
    iho = input_html_options || {}

    if options[:remote]
      options[:collection] = autocomplete_collection
      iho[:class] = [iho[:class], 'f-c-collection-remote-select-input'].flatten

      if options[:remote] == true
        iho['data-autocomplete-url'] = autocomplete_url
      else
        iho['data-autocomplete-url'] = options[:remote]
      end
    end

    label_method, value_method = detect_collection_methods
    merged_input_options = merge_wrapper_options(iho, wrapper_options)

    @builder.collection_select(
      attribute_name, collection, value_method, label_method,
      input_options, merged_input_options
    )
  end

  def autocomplete_url
    Folio::Engine.routes
                 .url_helpers
                 .url_for([:selectize,
                           :console,
                           :api,
                           :autocomplete,
                           klass: reflection.class_name,
                           only_path: true])
  end

  def autocomplete_collection
    value = object.try(attribute_name)

    if value.present?
      if value.is_a?(Array)
        value.map do |val|
          obj = reflection.class_name.constantize.find(val)
          [obj.to_console_label, val]
        end
      else
        obj = reflection.class_name.constantize.find(value)
        [[obj.to_console_label, value]]
      end
    else
      []
    end
  end
end
