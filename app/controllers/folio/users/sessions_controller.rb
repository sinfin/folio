# frozen_string_literal: true

class Folio::Users::SessionsController < Devise::SessionsController
  def new
    if params[:pending] && session[:pending_folio_authentication_id]
      timestamp = Time.zone.parse(session[:pending_folio_authentication_id]["timestamp"])

      if timestamp > 1.hour.ago
        @pending_authentication = Folio::Omniauth::Authentication.find_by(id: session[:pending_folio_authentication_id]["id"])
        super unless @pending_authentication
      else
        super
      end
    else
      super
    end
  end

  def create
    respond_to do |format|
      format.html { super }

      format.json do
        self.resource = warden.authenticate(auth_options)

        if resource
          sign_in(resource_name, resource)
          @force_flash = true
          set_flash_message!(:notice, :signed_in)

          render json: {
            data: {
              url: stored_location_for(:user).presence || after_sign_in_path_for(resource),
            }
          }, status: 200
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

  def is_flashing_format?
    if @force_flash
      true
    else
      super
    end
  end
end
