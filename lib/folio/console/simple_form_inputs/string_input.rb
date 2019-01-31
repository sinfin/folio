# frozen_string_literal: true

SimpleForm::Inputs::StringInput.class_eval do
  def input(wrapper_options = nil)
    if string?
      if options[:autocomplete]
        if options[:autocomplete].is_a?(Array)
          collection = options[:autocomplete].to_json
        else
          collection = @builder.object
                               .class
                               .distinct
                               .pluck(attribute_name)
                               .compact
                               .sort_by { |name| I18n.transliterate(name) }
                               .to_json
        end
        input_html_options['data-autocomplete'] = collection
        input_html_classes << 'folio-console-string-input'
        input_html_classes << 'folio-console-string-input--autocomplete'
      end
    else
      input_html_classes.unshift('string')
      input_html_options[:type] ||= input_type if html5?
    end

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    @builder.text_field(attribute_name, merged_input_options)
  end
end
