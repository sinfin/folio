# frozen_string_literal: true

class Folio::Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Folio::Users::DeviseControllerBase

  def facebook
    bind_user_and_redirect
  end

  def twitter
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
  end

  private
    def bind_user_and_redirect
      auth = Folio::Omniauth::Authentication.from_request(request)

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
          else
            existing_user = nil
          end

          session[:pending_folio_authentication] = {
            timestamp: Time.zone.now,
            id: auth.id,
            conflict: true,
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
end
