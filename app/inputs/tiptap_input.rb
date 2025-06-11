# frozen_string_literal: true

class TiptapInput < SimpleForm::Inputs::HiddenInput
  def input(wrapper_options = nil)
    register_stimulus("f-input-tiptap", wrapper: true)

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    @builder.hidden_field(attribute_name, merged_input_options)
  end
end
