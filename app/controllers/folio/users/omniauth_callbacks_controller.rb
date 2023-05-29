# frozen_string_literal: true

class Folio::Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Folio::Users::DeviseControllerBase

  def facebook
    bind_user_and_redirect
  end

  def twitter2
    bind_user_and_redirect
  end

  def apple
    bind_user_and_redirect
  end

  def google_oauth2
    bind_user_and_redirect
  end

  def new_user
    auth_data = session[:pending_folio_authentication]

    if auth_data &&
      auth_data["timestamp"] &&
      auth_data["timestamp"].to_datetime > 1.hour.ago &&
      @auth = Folio::Omniauth::Authentication.find_by_id(auth_data["id"])
      @user = Folio::User.new_from_auth(@auth)
    else
      session.delete(:pending_folio_authentication)
      redirect_to main_app.new_user_session_path,
                  flash: { alert: t("folio.users.omniauth_callbacks.new_user.invalid_session_data") }
    end
  end

  def create_user
    auth_data = session[:pending_folio_authentication]

    if auth_data &&
      auth_data["timestamp"] &&
      auth_data["timestamp"].to_datetime > 1.hour.ago &&
      @auth = Folio::Omniauth::Authentication.find_by_id(auth_data["id"])
      @user = Folio::User.new_from_auth(@auth)

      @user.assign_attributes(create_user_params)
      @user.password = "#{Devise.friendly_token[0, 20]}a6C" # appendix to always fullfill standard requirements
      @user.has_generated_password = true

      if @user.save
        session.delete(:pending_folio_authentication)

        sign_in(resource_name, @user)
        set_flash_message!(:notice, :signed_in) if is_flashing_format?
        resource.after_database_authentication

        redirect_to after_sign_in_path_for(resource)
      else
        flash.now[:alert] = t("folio.users.omniauth_callbacks.create_user.failure")
        render :new_user
      end
    else
      session.delete(:pending_folio_authentication)
      redirect_to main_app.new_user_session_path,
                  flash: { alert: t("folio.users.omniauth_callbacks.new_user.invalid_session_data") }
    end
  end

  def conflict
    auth_data = session[:pending_folio_authentication]

    if auth_data &&
       auth_data["timestamp"] &&
       auth_data["timestamp"].to_datetime > 1.hour.ago &&
       auth_data["conflict"]
      @auth = Folio::Omniauth::Authentication.find_by_id(auth_data["id"])
      Rails.application.config.devise.mailer.omniauth_conflict(@auth).deliver_later
    else
      session.delete(:pending_folio_authentication)
      redirect_to main_app.new_user_session_path
    end
  end

  def resolve_conflict
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
    end

    redirect_to main_app.new_user_session_path
  end

  private
    def bind_user_and_redirect
      auth = Folio::Omniauth::Authentication.from_request(request)

      if request.env["omniauth.origin"] && Folio::Site.any? { |site| request.env["omniauth.origin"].include?(site.env_aware_domain) }
        store_location_for(:user, request.env["omniauth.origin"])
      end

      if user_signed_in?
        target_url = stored_location_for(:user).presence || main_app.send(Rails.application.config.folio_users_after_sign_in_path)

        if auth.user.nil?
          # it's a new Authentication
          auth.user = current_user
          auth.save!

          if current_user.reload.authentications.where(provider: auth.provider).size == 1
            msg = t("folio.users.omniauth_callbacks.added_provider",
                    provider: auth.human_provider)
            redirect_to target_url, flash: { success: msg }
          else
            set_flash_message!(:success, :signed_in)
            redirect_to target_url
          end
        else
          set_flash_message!(:success, :signed_in)
          redirect_to target_url
        end
      else
        if user = auth.user
          sign_in(:user, user)

          set_flash_message!(:success, :signed_in)
          redirect_to after_sign_in_path_for(resource)
        else
          email = auth.email

          if email.present?
            existing_user = Folio::User.find_by(email:)

            if existing_user
              conflict_token = nil

              loop do
                conflict_token = SecureRandom.urlsafe_base64(16).gsub(/-|_/, ("a".."z").to_a[rand(26)])
                break unless Folio::Omniauth::Authentication.exists?(conflict_token:)
              end

              auth.update_columns(conflict_user_id: existing_user.id,
                                  conflict_token:)
            end
          else
            existing_user = nil
          end

          session[:pending_folio_authentication] = {
            timestamp: Time.zone.now,
            id: auth.id,
            conflict: !!existing_user,
          }

          if existing_user
            # prompt the user to add auth to an existing user and sign in after
            redirect_to main_app.users_auth_conflict_path
          else
            # prompt the user to create a new user
            redirect_to main_app.users_auth_new_user_path
          end
        end
      end
    end

    def create_user_params
      params.require(:user)
            .permit(:email,
                    *Folio::User.controller_strong_params_for_create)
    end

    def verified_request?
      # fix of `ERROR -- omniauth: (apple) Authentication failure! csrf_detected: OmniAuth::Strategies::OAuth2::CallbackError, csrf_detected | CSRF detected`
      # see https://github.com/nhosoya/omniauth-apple/issues/54#issuecomment-1409644107
      action_name == "apple" || super
    end
end
