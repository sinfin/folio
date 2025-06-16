# frozen_string_literal: true

class TiptapInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options = nil)
    register_stimulus("f-input-tiptap",
                      wrapper: true,
                      values: { loaded: false },
                      action: { "message@window" => "onWindowMessage" })

    input_html_options[:hidden] = true

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    options[:custom_html] = <<~HTML.html_safe
      <div class="f-input-tiptap__inner">
        <span class="f-input-tiptap__loader folio-loader" data-f-input-tiptap-target="loader"></span>
        <iframe class="f-input-tiptap__iframe" data-f-input-tiptap-target="iframe" src="/folio-tiptap/#{options[:block] ? "block" : "rich_text"}_editor"></iframe>
      </div>
    HTML

    @builder.hidden_field(attribute_name, merged_input_options)
  end
end
