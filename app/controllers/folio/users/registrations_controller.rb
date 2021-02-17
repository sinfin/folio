# frozen_string_literal: true

class Folio::Users::RegistrationsController < Devise::RegistrationsController
  def create
    respond_to do |format|
      format.html { super }

      format.json do
        devise_parameter_sanitizer.permit(:sign_up, keys: [:nickname, :phone])

        build_resource(sign_up_params)

        resource.save

        if resource.persisted?
          @force_flash = true

          if resource.active_for_authentication?
            set_flash_message! :notice, :signed_up
            sign_up(resource_name, resource)
          else
            set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
            expire_data_after_sign_in!
          end

          render json: {
            data: {
              url: stored_location_for(:user).presence || root_path,
            }
          }, status: 200
        else
          clean_up_passwords resource
          set_minimum_password_length

          message = t(".failure")

          errors = [{ status: 401, title: "Unauthorized", detail: message }]
          cell_flash = ActionDispatch::Flash::FlashHash.new
          cell_flash[:alert] = message

          html = cell("folio/devise/registrations/new",
                      resource: resource,
                      resource_name: :user,
                      modal: true,
                      flash: cell_flash).show

          render json: { errors: errors, data: html }, status: 401
        end
      end
    end
  end

  def update_resource(resource, params)
    if resource.authentications.blank?
      resource.update_with_password(params)
    else
      resource.update(params)
    end
  end

  def is_flashing_format?
    if @force_flash
      true
    else
      super
    end
  end

  private
    def sign_up_params
      params.require(:user).permit(:first_name, :last_name).to_h.merge(super)
    end
end
