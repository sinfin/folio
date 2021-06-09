# frozen_string_literal: true

class Folio::Devise::Confirmations::NewCell < Folio::Devise::ApplicationCell
  def show
    render if ::Rails.application.config.folio_users_confirmable
  end

  def form(&block)
    opts = {
      url: controller.confirmation_path(resource_name),
      as: resource_name,
      html: {
        method: :post,
        class: "f-devise-confirmations-new__form"
      },
    }

    resource.email ||= email_value

    simple_form_for(resource, opts, &block)
  end

  def email_value
    resource.pending_reconfirmation? ? resource.unconfirmed_email : resource.email
  end
end
