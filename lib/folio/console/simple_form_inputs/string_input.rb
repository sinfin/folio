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

        input_html_classes << 'folio-console-string-input'

        if collection
          input_html_options['data-autocomplete'] = collection
          input_html_classes << 'folio-console-string-input--autocomplete'
        elsif remote_autocomplete
          input_html_options['data-remote-autocomplete'] = remote_autocomplete
          input_html_classes << 'folio-console-string-input--remote-autocomplete'
        end
      end
    else
      input_html_classes.unshift('string')
      input_html_options[:type] ||= input_type if html5?
    end

    if options[:locale]
      input_html_options['data-locale'] = options[:locale]
    end

    if options[:folio_label]
      input_html_classes << 'f-c-js-atoms-placement-label'
    elsif options[:folio_perex]
      input_html_classes << 'f-c-js-atoms-placement-perex'
    end

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    @builder.text_field(attribute_name, merged_input_options)
  end
end
