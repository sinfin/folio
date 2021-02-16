# frozen_string_literal: true

class Folio::Users::SessionsController < Devise::SessionsController
  def create
    respond_to do |format|
      format.html { super }

      format.json do
        self.resource = warden.authenticate(auth_options)

        if resource
          sign_in(resource_name, resource)
          set_flash_message!(:notice, :signed_in)
          render json: {}, status: 200
        else
          message = I18n.t("devise.failure.invalid", authentication_keys: resource_class.authentication_keys.join(", "))

          errors = [{ status: 401, title: "Unauthorized", detail: message }]
          cell_flash = ActionDispatch::Flash::FlashHash.new
          cell_flash[:alert] = message

          html = cell("folio/devise/sessions/new",
                      resource: resource || Folio::User.new,
                      resource_name: :user,
                      modal: true,
                      flash: cell_flash).show

          render json: { errors: errors, data: html }, status: 401
        end
      end
    end
  end

  def after_sign_in_path_for(_resource)
    root_path
  end

  def after_sign_out_path_for(_resource)
    new_user_session_path
  rescue ActionController::UrlGenerationError
    main_app.new_user_session_path
  end
end
