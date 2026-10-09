# frozen_string_literal: true

class UrlJsonInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options = nil)
    input_html = register_url_input(json: true, wrapper_options:, options:)
    custom_html = options.delete(:custom_html)

    @builder.template.safe_join([
      input_html,
      @builder.template.content_tag(:div, custom_html, class: "form-group__custom-html"),
    ])
  end
end
