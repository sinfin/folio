# frozen_string_literal: true

class Folio::Devise::Invitations::ShowCell < Folio::Devise::ApplicationCell
  def show
    render if model && model[:email].present?
  end

  def form(&block)
    opts = {
      url: controller.invitation_path(resource_name),
      as: resource_name,
      html: {
        id: nil
      },
    }

    simple_form_for(resource, opts, &block)
  end

  def resource
    @resource ||= if model[:resource] && model[:resource].persisted?
      model[:resource]
    else
      model[:resource].class.find_by(email: model[:email], sign_in_count: 0) || model[:resource]
    end
  end
end
