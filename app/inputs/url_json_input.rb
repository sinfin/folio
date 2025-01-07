# frozen_string_literal: true

class UrlJsonInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options = nil)
    register_url_input(json: true, wrapper_options:)
  end
end
