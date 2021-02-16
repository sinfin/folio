# frozen_string_literal: true

class Folio::Devise::Registrations::NewCell < Folio::Devise::ApplicationCell
  def form(&block)
    opts = {
      url: controller.registration_path(resource_name),
      as: resource_name,
      html: { class: "f-devise-registrations-new__form" },
    }

    simple_form_for(resource, opts, &block)
  end
end
