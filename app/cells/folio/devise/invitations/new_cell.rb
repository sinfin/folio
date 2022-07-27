# frozen_string_literal: true

class Folio::Devise::Invitations::NewCell < Folio::Devise::ApplicationCell
  def form(&block)
    opts = {
      url: controller.invitation_path(resource_name),
      as: resource_name,
      html: {
        class: model[:modal] ? "f-devise-modal__form" : nil,
        id: nil,
        "data-failure" => t(".failure"),
      },
    }

    simple_form_for(resource, opts, &block)
  end
end
