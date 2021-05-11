# frozen_string_literal: true

class Folio::Users::SessionsController < Devise::SessionsController
  include Folio::Users::DeviseControllerBase

  def new
    if params[:conflict_token].present?
      authentication = Folio::Omniauth::Authentication.find_by(conflict_token: params[:conflict_token])

      if authentication.present?
        session.delete(:pending_folio_authentication_id)
        @user = Folio::User.find_by_id(authentication.conflict_user_id)
        authentication.update_columns(folio_user_id: @user.id,
                                      conflict_token: nil,
                                      conflict_user_id: nil)
        sign_in(resource_name, @user)
        @force_flash = true
        set_flash_message!(:notice, :signed_in)
        redirect_to stored_location_for(:user).presence || after_sign_in_path_for(@user)
        return
      end

      redirect_to main_app.new_user_session_path, flash: { alert: t("folio.devise.sessions.new.invalid_conflict_token_flash") }
    elsif params[:pending] && session[:pending_folio_authentication_id]
      timestamp = Time.zone.parse(session[:pending_folio_authentication_id]["timestamp"])

      if timestamp > 1.hour.ago
        @pending_authentication = Folio::Omniauth::Authentication.find_by(id: session[:pending_folio_authentication_id]["id"])

        if @pending_authentication
          Rails.application.config.devise.mailer.omniauth_conflict(@pending_authentication).deliver_later
        end

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

  def is_flashing_format?
    if @force_flash
      true
    else
      super
    end
  end
end
