# frozen_string_literal: true

SimpleForm::Inputs::CollectionSelectInput.class_eval do
  def input(wrapper_options = nil)
    iho = input_html_options || {}

    if options[:remote]
      options[:collection] = autocomplete_collection
      iho[:class] = [iho[:class], "f-c-collection-remote-select-input"].flatten

      if options[:remote] == true
        iho["data-autocomplete-url"] = autocomplete_url
      elsif options[:remote].is_a?(Hash)
        iho["data-autocomplete-url"] = autocomplete_url(options[:remote])
      else
        iho["data-autocomplete-url"] = options[:remote]
      end
    end

    if options[:atom_setting]
      iho[:class] = [iho[:class], "f-c-js-atoms-placement-setting"].flatten
      iho["data-atom-setting"] = options[:atom_setting]
    end

    label_method, value_method = detect_collection_methods
    merged_input_options = merge_wrapper_options(iho, wrapper_options)

    @builder.collection_select(
      attribute_name, collection, value_method, label_method,
      input_options, merged_input_options
    )
  end

  def autocomplete_url(opts = {})
    Folio::Engine.routes
                 .url_helpers
                 .url_for([:selectize,
                           :console,
                           :api,
                           :autocomplete,
                           klass: reflection.class_name,
                           scope: opts[:scope],
                           order_scope: opts[:order_scope],
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
