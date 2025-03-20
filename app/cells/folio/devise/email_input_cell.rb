# frozen_string_literal: true

class Folio::Devise::EmailInputCell < Folio::Devise::ApplicationCell
  def input
    model.input :email,
                wrapper: false,
                label: false,
                required: true,
                disabled: options[:disabled],
                placeholder: options[:placeholder],
                input_html: {
                  autofocus: options[:autofocus].nil? ? true : options[:autofocus],
                  autocomplete: "email",
                  value: model.object.email.presence,
                  data: { test_id: options[:test_id].presence },
                  id: input_id, # need ID for generating "<label for",
                  # but there can be more same inputs on page
                  # so we need to generate unique ID
                }.merge(options[:input_html] || {})
  end

  def input_id
    @input_id ||= "email_#{SecureRandom.hex(4)}"
  end
end
