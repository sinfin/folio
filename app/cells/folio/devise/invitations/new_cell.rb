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

  def data
    h = stimulus_controller("f-devise-invitations-new")

    if model[:modal]
      h.merge!(stimulus_controller("f-devise-modal-form", inline: true))
    end

    h["f-devise-invitations-new-f-devise-omniauth-forms-outlet"] = ".f-devise-omniauth-forms"
    h["f-devise-invitations-new-f-devise-omniauth-outlet"] = ".f-devise-omniauth"

    h
  end
end
