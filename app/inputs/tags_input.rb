# frozen_string_literal: true

class TagsInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options = nil)
    input_html_options[:class] ||= []
    input_html_options[:class] << " f-input f-input--tags"

    register_atom_settings

    stimulus_opts = options.slice(:tags_context, :url)
    stimulus_opts[:url] ||= Folio::Engine.routes
                                         .url_helpers
                                         .console_api_tags_path(context: stimulus_opts[:tags_context])

    register_stimulus("f-input-tags", stimulus_opts)

    value = object.send(attribute_name)

    if value.is_a?(Array)
      input_html_options[:value] = value.join(", ")
    end

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    @builder.text_field(attribute_name, merged_input_options)
  end
end
