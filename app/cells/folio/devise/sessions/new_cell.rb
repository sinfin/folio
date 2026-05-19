# frozen_string_literal: true

class Folio::Devise::Sessions::NewCell < Folio::Devise::ApplicationCell
  DEV_LOGIN_CREDENTIAL = "test@test.test"

  def form(&block)
    opts = {
      url: controller.session_path(resource_name),
      as: resource_name,
      html: {
        class: model[:modal] ? "f-devise-modal__form" : nil,
        id: nil,
        "data-failure" => t(".failure"),
      },
    }

    simple_form_for(resource, opts, &block)
  end

  def dev_login?
    return false unless ::Rails.env.development?

    user = ::Folio::User.find_by(email: DEV_LOGIN_CREDENTIAL)
    user&.valid_password?(DEV_LOGIN_CREDENTIAL) || false
  end
end
