# frozen_string_literal: true

class Folio::Devise::ModalCell < Folio::ApplicationCell
  CLASS_NAME_BASE = "f-devise-modal"
  CLASS_NAME = ".#{CLASS_NAME_BASE}"

  def devise_model
    if model.present?
      {
        resource: Folio::User.new,
        resource_name: :user,
        modal: true,
        modal_non_get_request: controller.request.method != "GET",
      }.merge(model)
    else
      {
        resource: Folio::User.new,
        resource_name: :user,
        modal: true,
        modal_non_get_request: controller.request.method != "GET",
      }
    end
  end
end
