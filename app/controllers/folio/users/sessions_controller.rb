# frozen_string_literal: true

class Folio::Users::SessionsController < Devise::SessionsController
  include Folio::Users::DeviseControllerBase
  include Folio::Captcha::HasTurnstileValidation

  protect_from_forgery prepend: true

  def destroy
    if Folio::Current.user
      if Rails.application.config.folio_crossdomain_devise || Rails.application.config.folio_users_sign_out_everywhere
        Folio::Current.user.sign_out_everywhere!
      end
    end

    super
  end

  def new
    # Superadmin is signed in even if the Turnstile validation fails (order of before_actions)
    sign_out(:user) if current_user

    self.resource = resource_class.new(sign_in_params)
    self.resource.email = session[:user_email] if session[:user_email].present?
    clean_up_passwords(resource)
    session.delete(:user_email)
    yield resource if block_given?
    respond_with(resource, serialize_options(resource))
  end

  def create
    # User is logged in before this happens and it messes with the last_sign_in_at timestamp
    warden.logout(resource_name) if warden.authenticated?(resource_name)
    reset_session

    if invited_user?
      render plain: invitation_controller.process("create")
    else
      respond_to do |format|
        format.html do
          resource = find_and_validate_user

          if resource
            if resource.needs_magic_link_verification?
              resource.send_magic_link(email: resource.email)

              session[:login_confirmation_user_id] = resource.id
              session[:login_confirmation_email] = resource.email
              return redirect_to main_app.users_auth_login_confirmation_path
            else
              sign_in(resource_name, resource)
              set_flash_message!(:notice, :signed_in)

              yield resource if block_given?
              respond_with resource, location: after_sign_in_path_for(resource)
            end
          else
            session[:user_email] = params[:user][:email]
            redirect_to main_app.new_user_session_path, flash: { alert: @exception_message || I18n.t("folio.devise.sessions.create.invalid") }
          end
        end

        format.json do
          store_sign_in_location
          resource = find_and_validate_user

          if resource
            if resource.needs_magic_link_verification?(request)
              resource.send_magic_link(email: resource.email)

              render json: {
                data: { redirect: main_app.users_auth_login_confirmation_path }
              }, status: 200
            else
              sign_in(resource_name, resource)

              @force_flash = true
              set_flash_message!(:notice, :signed_in)
              render json: { data: { url: after_sign_in_path_for(resource) } }, status: 200
            end
          else
            exception_message = @exception_message || I18n.t("folio.devise.sessions.create.invalid")
            errors = [{ status: 401, title: "Unauthorized", detail: exception_message }]
            cell_flash = ActionDispatch::Flash::FlashHash.new
            cell_flash[:alert] = exception_message

            html = cell("folio/devise/sessions/new",
                        resource: Folio::User.new(email: params[:user][:email]),
                        resource_name: :user,
                        modal: true,
                        flash: cell_flash,
                        modal_non_get_request: params[:modal_non_get_request].present?).show

            render json: { errors:, data: html }, status: 401
          end
        end
      end
    end
  end

  def login_confirmation
    @user_id = session[:login_confirmation_user_id]
    @email = session[:login_confirmation_email]

    redirect_to main_app.new_user_session_path unless @user_id
  end

  def resend_login_confirmation
    user_id = session[:login_confirmation_user_id]

    if user_id
      user = Folio::User.find_by(id: user_id)

      if user
        user.send_magic_link(email: user.email)
        flash[:notice] = t("folio.users.sessions.login_confirmation.resent")
      else
        flash[:error] = I18n.t("folio.devise.sessions.create.invalid")
        return redirect_to main_app.new_user_session_path
      end
    end

    redirect_to main_app.users_auth_login_confirmation_path
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

  def require_no_authentication
    safe_set_up_current_from_request

    result = handle_crossdomain_devise

    if result && result.action == :noop
      if Folio::Current.user && !request.format.json?
        set_flash_message!(:notice, :signed_in)
        redirect_to after_sign_in_path_for(Folio::Current.user)
        after_sign_in
      else
        super
      end
    end
  end

  def invited_user?
    Rails.application.config.folio_users_publicly_invitable &&
    params[:user] &&
    params[:user][:email].present? &&
    email_belongs_to_invited_pending_user?(params[:user][:email])
  end

  def invitation_controller
    controller = self.class.to_s.gsub("Sessions", "Invitations").constantize.new
    controller.request = request
    controller.response = response
    controller
  end

  def try_to_authenticate_resource
    warden_exception_or_user = catch :warden do
      self.resource = warden.authenticate!(auth_options)
    end

    return nil if resource

    get_failure_flash_message(warden_exception_or_user)
  end

  def store_sign_in_location
    if request.referrer
      if params[:modal_non_get_request].blank?
        store_location_for(:user, request.referrer)
      elsif path = Rails.application.config.folio_users_non_get_referrer_rewrite_proc.call(request.referrer)
        store_location_for(:user, path)
      else
        store_location_for(:user, main_app.send(Rails.application.config.folio_users_after_sign_in_path))
      end
    else
      store_location_for(:user, main_app.send(Rails.application.config.folio_users_after_sign_in_path))
    end
  end

  def turnstile_failure_redirect_path
    new_user_session_path
  end

  def find_and_validate_user
    @exception_message = nil

    return nil unless params[:user]&.dig(:email).present? && params[:user]&.dig(:password).present?

    user = resource_class.find_for_database_authentication(email: params[:user][:email], auth_site_id: params[:user][:auth_site_id])

    return nil unless user

    if user.valid_password?(params[:user][:password])
      if user.respond_to?(:active_for_authentication?) && !user.active_for_authentication?
        @exception_message = get_failure_flash_message({ message: user.inactive_message })
        return nil
      end

      user
    else
      @exception_message = get_failure_flash_message({ message: nil })
      nil
    end
  end
end
