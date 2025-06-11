# frozen_string_literal: true

class RedactorInput < SimpleForm::Inputs::TextInput
  def input(wrapper_options = nil)
    register_stimulus("f-input-redactor", wrapper: true)

    if options[:content_templates]
      ct_klass = options[:content_templates].constantize
      edit_url = if ::Rails.application.config.folio_content_templates_editable
        Folio::Engine.app.url_helpers.edit_console_content_templates_path(type: options[:content_templates])
      end

      register_stimulus("f-input-content-templates",
                        values: { edit_url:,
                                  title: ct_klass.model_name.human(count: 2),
                                  templates: ct_klass.by_site(Folio::Current.site).to_data_attribute })
    end

    register_atom_settings

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    @builder.text_area(attribute_name, merged_input_options)
  end
end
