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
                  id: input_id,
                  value: options[:keep_password] ? model.object.send(options[:field]) : nil,
                }
  end

  def input_id
    @input_id ||= "#{options[:field]}_#{SecureRandom.hex(4)}"
  end
end
