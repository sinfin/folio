# frozen_string_literal: true

class Folio::Devise::Invitations::EditCell < Folio::Devise::ApplicationCell
  def form(&block)
    opts = {
      url: controller.invitation_path(resource_name),
      as: resource_name,
      html: {
        method: :put,
        class: "f-devise-invitations-edit__form"
      },
    }

    simple_form_for(resource, opts, &block)
  end

  def invitation_token
    resource.invitation_token || params[:invitation_token]
  end
end
