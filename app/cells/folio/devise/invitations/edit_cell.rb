# frozen_string_literal: true

class Folio::Devise::Invitations::EditCell < Folio::ApplicationCell
  include SimpleForm::ActionViewExtensions::FormHelper

  def form(&block)
    opts = {
      url: controller.invitation_path(model[:resource_name]),
      as: model[:resource_name],
      html: {
        method: :put,
        class: "f-devise-invitations-edit__form"
      },
    }

    simple_form_for(model[:resource], opts, &block)
  end

  def invitation_token
    model[:resource].invitation_token || params[:invitation_token]
  end
end
