# frozen_string_literal: true

SimpleForm::Inputs::TextInput.class_eval do
  def input(wrapper_options = nil)
    input_html_classes << "f-c-text-input"

    if options[:autosize]
      input_html_classes << "f-c-text-input--autosize"
    end

    if options[:locale]
      input_html_options["data-locale"] = options[:locale]
    end

    if options[:character_counter]
      input_html_classes << "f-c-string-input--character-counter"
      input_html_options["data-character-counter"] = options[:character_counter]
    end

    if options[:folio_label]
      input_html_classes << "f-c-js-atoms-placement-label"
    elsif options[:folio_perex]
      input_html_classes << "f-c-js-atoms-placement-perex"
    elsif options[:atom_setting]
      input_html_classes << "f-c-js-atoms-placement-setting"
      input_html_options["data-atom-setting"] = options[:atom_setting]
    end

    if options[:content_templates]
      ct_klass = options[:content_templates].constantize
      input_html_options["data-content-templates"] = ct_klass.to_data_attribute
      input_html_options["data-content-templates-url"] = Folio::Engine.app.url_helpers.edit_console_content_templates_path(type: options[:content_templates])
      input_html_options["data-content-templates-title"] = ct_klass.model_name.human(count: 2)
      input_html_classes << "f-c-string-input--content-templates"
    end

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    @builder.text_area(attribute_name, merged_input_options)
  end
end
