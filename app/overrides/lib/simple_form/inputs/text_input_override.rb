# frozen_string_literal: true

SimpleForm::Inputs::TextInput.class_eval do
  def input(wrapper_options = nil)
    if options[:autosize]
      register_stimulus("f-input-autosize")
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
      edit_url = if ::Rails.application.config.folio_content_templates_editable
        Folio::Engine.app.url_helpers.edit_console_content_templates_path(type: options[:content_templates])
      end

      register_stimulus("f-input-content-templates",
                        { edit_url:, title: ct_klass.model_name.human(count: 2), templates: ct_klass.to_data_attribute })
    end

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    @builder.text_area(attribute_name, merged_input_options)
  end
end
