# frozen_string_literal: true

SimpleForm::Inputs::CollectionSelectInput.class_eval do
  def input(wrapper_options = nil)
    iho = input_html_options || {}

    if options[:remote]
      reflection_class_name = options[:reflection_class_name] || reflection.try(:class_name)

      options[:collection] = autocomplete_collection(options[:force_collection] ? options[:collection] : nil, reflection_class_name: options[:reflection_class_name])
      input_html_classes << "f-input" if input_html_classes.exclude?("f-input")

      stimulus_opts = {}

      if options[:include_blank].is_a?(String)
        stimulus_opts[:include_blank] = options[:include_blank]
      end

      if options[:remote] == true
        stimulus_opts[:url] = autocomplete_url(reflection_class_name:)
      elsif options[:remote].is_a?(Hash)
        stimulus_opts[:url] = autocomplete_url(options[:remote])
      else
        stimulus_opts[:url] = options[:remote]
      end

      register_stimulus("f-input-collection-remote-select", stimulus_opts)
      iho[:id] = nil unless iho[:id].present?
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

  def autocomplete_url(opts = {}, reflection_class_name:)
    Folio::Engine.routes
                 .url_helpers
                 .url_for([:select2,
                           :console,
                           :api,
                           :autocomplete,
                           klass: reflection_class_name,
                           scope: opts[:scope],
                           order_scope: opts[:order_scope],
                           only_path: true])
  end

  def autocomplete_collection(default_collection, reflection_class_name:)
    value = object.try(attribute_name)

    if value.present? && reflection_class_name
      if value.is_a?(Array)
        value.map do |val|
          obj = reflection_class_name.constantize.find(val)
          ary = [obj.to_console_label, val]
          ary << obj.form_select_data if obj.try(:form_select_data)

          ary
        end
      else
        obj = reflection_class_name.constantize.find(value)
        ary = [obj.to_console_label, value]
        ary << obj.form_select_data if obj.try(:form_select_data)

        [ary]
      end
    else
      default_collection || []
    end
  end
end
