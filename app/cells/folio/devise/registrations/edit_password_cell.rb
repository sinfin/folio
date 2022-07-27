# frozen_string_literal: true

class Folio::Devise::Registrations::EditPasswordCell < Folio::Devise::ApplicationCell
  def form(&block)
    opts = {
      url: controller.users_registrations_update_password_path,
      as: :user,
      html: { class: "f-devise-registrations-edit-password__form", method: :patch },
    }

    simple_form_for(resource, opts, &block)
  end
end
