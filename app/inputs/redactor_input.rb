# frozen_string_literal: true

class RedactorInput < SimpleForm::Inputs::TextInput
  def input(wrapper_options = nil)
    input_html_options[:class] ||= []
    input_html_options[:class] << " f-input--redactor"

    if options[:redactor]
      input_html_options[:class] << " f-input--redactor-#{options[:redactor]}"
    end

    if options[:folio_label]
      input_html_options[:class] << "f-c-js-atoms-placement-label"
    elsif options[:folio_perex]
      input_html_options[:class] << "f-c-js-atoms-placement-perex"
    elsif options[:atom_setting]
      input_html_options[:class] << "f-c-js-atoms-placement-setting"
      input_html_options["data-atom-setting"] = options[:atom_setting]
    end

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    @builder.text_area(attribute_name, merged_input_options)
  end
end
