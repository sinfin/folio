# frozen_string_literal: true

class AdvancedRedactorInput < RedactorInput
  def input(wrapper_options = nil)
    register_stimulus("f-input-redactor",
                      wrapper: true,
                      action: {
                        "f-special-characters-popup:insertText" => "onSpecialCharactersInsertText",
                      })
    add_text_suggestions(input_type: :text)

    input_html_options[:class] << "f-input--redactor-advanced"

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    @builder.text_area(attribute_name, merged_input_options)
  end
end
