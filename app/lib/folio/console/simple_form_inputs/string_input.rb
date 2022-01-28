# frozen_string_literal: true

SimpleForm::Inputs::StringInput.class_eval do
  def input(wrapper_options = nil)
    if string?
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

        input_html_classes << "f-c-string-input"

        if collection
          input_html_options["data-autocomplete"] = collection
          input_html_classes << "f-c-string-input--autocomplete"
        elsif remote_autocomplete
          input_html_options["data-remote-autocomplete"] = remote_autocomplete
          input_html_classes << "f-c-string-input--remote-autocomplete"
        end
      end
    elsif options[:numeral]
      input_html_classes << "f-c-string-input--numeral"
      input_html_options[:autocomplete] = "off"
    else
      input_html_classes.unshift("string")
      input_html_options[:type] ||= input_type if html5?
    end

    if options[:character_counter]
      input_html_classes << "f-c-string-input--character-counter"
      input_html_options["data-character-counter"] = options[:character_counter]
    end

    if options[:content_templates]
      ct_klass = options[:content_templates].constantize
      input_html_options["data-content-templates"] = ct_klass.to_data_attribute
      input_html_options["data-content-templates-url"] = Folio::Engine.app.url_helpers.edit_console_content_templates_path(type: options[:content_templates])
      input_html_options["data-content-templates-title"] = ct_klass.model_name.human(count: 2)
      input_html_classes << "f-c-string-input--content-templates"
    end

    if options[:locale]
      input_html_options["data-locale"] = options[:locale]
    end

    if options[:folio_label]
      input_html_classes << "f-c-js-atoms-placement-label"
    elsif options[:folio_perex]
      input_html_classes << "f-c-js-atoms-placement-perex"
    elsif options[:atom_setting]
      input_html_classes << "f-c-js-atoms-placement-setting"
      input_html_options["data-atom-setting"] = options[:atom_setting]
    end

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    @builder.text_field(attribute_name, merged_input_options)
  end
end
