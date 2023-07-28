# frozen_string_literal: true

SimpleForm::Inputs::TextInput.class_eval do
  def input(wrapper_options = nil)
    if options[:autosize]
      input_html_classes << "f-input"
      input_html_classes << "f-input--autosize"
    end

    if options[:locale]
      input_html_options["data-locale"] = options[:locale]
    end

    if options[:character_counter]
      register_stimulus("f-input-character-counter",
                        options[:character_counter].is_a?(Numeric) ? { max: options[:character_counter] } : {})
      input_html_options["data-action"] = "f-input-character-counter#onInput"
    end

    register_atom_settings

    if options[:content_templates]
      ct_klass = options[:content_templates].constantize
      input_html_options["data-content-templates"] = ct_klass.to_data_attribute
      input_html_options["data-content-templates-url"] = Folio::Engine.app.url_helpers.edit_console_content_templates_path(type: options[:content_templates])
      input_html_options["data-content-templates-title"] = ct_klass.model_name.human(count: 2)
      input_html_classes << "f-input" if input_html_classes.exclude?("f-input")
      input_html_classes << "f-input--content-templates"
    end

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    @builder.text_area(attribute_name, merged_input_options)
  end
end
