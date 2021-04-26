# frozen_string_literal: true

class Folio::Devise::PasswordInputCell < Folio::Devise::ApplicationCell
  def input
    model.input options[:field],
                wrapper: false,
                label: false,
                required: true,
                input_html: {
                  autocomplete: options[:autocomplete],
                  class: "f-devise-password-input__input",
                  id: nil,
                }
  end
end
