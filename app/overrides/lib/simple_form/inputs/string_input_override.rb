# frozen_string_literal: true

SimpleForm::Inputs::StringInput.class_eval do
  def input(wrapper_options = nil)
    if string? || input_type == :email
      if options[:autocomplete]
        collection = nil
        remote_autocomplete = nil

        if options[:autocomplete].is_a?(Array)
          collection = options[:autocomplete].to_json
        elsif options[:autocomplete].is_a?(String)
          remote_autocomplete = options[:autocomplete]
        else
          opts = [:field,
                  :console,
                  :api,
                  :autocomplete,
                  klass: object.class.to_s,
                  field: attribute_name,
                  only_path: true]
          remote_autocomplete = Folio::Engine.app.url_helpers.url_for(opts)
        end

        if collection
          input_html_options["data-autocomplete"] = collection
          input_html_classes << "f-input" if input_html_classes.exclude?("f-input")
          input_html_classes << "f-input--autocomplete"
        elsif remote_autocomplete
          input_html_options["data-remote-autocomplete"] = remote_autocomplete
          input_html_classes << "f-input" if input_html_classes.exclude?("f-input")
          input_html_classes << "f-input--remote-autocomplete"
        end
      end
    elsif options[:numeral]
      register_stimulus("f-input-numeral")
      input_html_options[:autocomplete] = "off"
    else
      input_html_classes.unshift("string")
      input_html_options[:type] ||= input_type if html5?
    end

    if options[:character_counter]
      register_stimulus("f-input-character-counter",
                        options[:character_counter].is_a?(Numeric) ? { max: options[:character_counter] } : {})
      input_html_options["data-action"] = "f-input-character-counter#onInput"
    end


    if options[:content_templates]
      ct_klass = options[:content_templates].constantize
      edit_url = if ::Rails.application.config.folio_content_templates_editable
        Folio::Engine.app.url_helpers.edit_console_content_templates_path(type: options[:content_templates])
      end

      register_stimulus("f-input-content-templates",
                        { edit_url:, title: ct_klass.model_name.human(count: 2), templates: ct_klass.to_data_attribute })
    end

    if options[:locale]
      input_html_options["data-locale"] = options[:locale]
    end

    register_atom_settings

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    @builder.text_field(attribute_name, merged_input_options)
  end
end
