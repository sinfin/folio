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

  def terms_agreement_label
    if model[:author_registration]
      t(".terms_agreement_author", terms_link:, privacy_link:)
    else
      t(".terms_agreement", terms_link:, privacy_link:)
    end
  end

  def author_registration_css_class
    model[:author_registration] ? "f-devise-invitations-new--author-registration" : nil
  end
end
