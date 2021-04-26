# frozen_string_literal: true

class Folio::Devise::Passwords::EditCell < Folio::Devise::ApplicationCell
  def form(&block)
    opts = {
      url: controller.password_path(resource_name),
      as: resource_name,
      html: { class: "f-devise-passwords-edit__form", method: :put },
    }

    simple_form_for(resource, opts, &block)
  end
end
