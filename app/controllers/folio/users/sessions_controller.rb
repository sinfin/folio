# frozen_string_literal: true

class Folio::Users::SessionsController < Devise::SessionsController
  include Folio::Users::DeviseControllerBase

  def new
    if params[:conflict_token].present?
      authentication = Folio::Omniauth::Authentication.find_by(conflict_token: params[:conflict_token])

      if authentication.present?
        session.delete(:pending_folio_authentication)
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
    elsif params[:pending] && session[:pending_folio_authentication]
      timestamp = Time.zone.parse(session[:pending_folio_authentication]["timestamp"])

      if timestamp > 1.hour.ago
        @pending_authentication = Folio::Omniauth::Authentication.find_by(id: session[:pending_folio_authentication]["id"])

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
      format.html do
        warden_exception_or_user = catch :warden do
          self.resource = warden.authenticate!(auth_options)
        end

        if resource
          set_flash_message!(:notice, :signed_in)
          sign_in(resource_name, resource)
          yield resource if block_given?
          respond_with resource, location: after_sign_in_path_for(resource)
        else
          message = get_failure_flash_message(warden_exception_or_user)
          redirect_to main_app.new_user_session_path, flash: { alert: message }
        end
      end

      format.json do
        warden_exception_or_user = catch :warden do
          self.resource = warden.authenticate(auth_options)
        end

        if resource
          sign_in(resource_name, resource)
          @force_flash = true
          set_flash_message!(:notice, :signed_in)
          render json: {}, status: 200
        else
          message = get_failure_flash_message(warden_exception_or_user)

          errors = [{ status: 401, title: "Unauthorized", detail: message }]
          cell_flash = ActionDispatch::Flash::FlashHash.new
          cell_flash[:alert] = message

          html = cell("folio/devise/sessions/new",
                      resource: resource || Folio::User.new(email: params[:user][:email]),
                      resource_name: :user,
                      modal: true,
                      flash: cell_flash).show

          render json: { errors:, data: html }, status: 401
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

  def get_failure_flash_message(warden_exception_or_user)
    if warden_exception_or_user.is_a?(Hash)
      if warden_exception_or_user[:message].nil?
        I18n.t("folio.devise.sessions.create.invalid")
      elsif warden_exception_or_user[:message] == :unconfirmed
        unconfirmed_flash_message
      else
        I18n.t("devise.failure.#{warden_exception_or_user[:message]}", default: unconfirmed_flash_message)
      end
    else
      I18n.t("devise.failure.invalid", authentication_keys: resource_class.authentication_keys.join(", "))
    end
  end

  def unconfirmed_flash_message
    link = ActionController::Base.helpers.link_to(I18n.t("folio.devise.confirmations.new.header"),
                                                  main_app.new_user_confirmation_path(email: params[:user] && params[:user][:email]))

    msg = I18n.t("devise.failure.unconfirmed")

    "#{msg} #{link}"
  end
end
