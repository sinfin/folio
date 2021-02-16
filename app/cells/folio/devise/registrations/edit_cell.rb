# frozen_string_literal: true

class Folio::Devise::Registrations::EditCell < Folio::Devise::ApplicationCell
  def form(&block)
    opts = {
      url: controller.registration_path(resource_name),
      as: resource_name,
      html: { class: "f-devise-registrations-edit__form" },
    }

    simple_form_for(resource, opts, &block)
  end

  def email_hint
    if controller.send(:devise_mapping).confirmable? && resource.pending_reconfirmation?
      t(".pending_reconfirmation", email: resource.unconfirmed_email)
    end
  end
end
