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
        elsif user = auth.find_or_create_user!
          sign_in(:user, user)
          set_flash_message!(:success, :signed_up)
          redirect_to after_sign_in_path_for(resource)
        else
          session[:pending_folio_authentication_id] = {
            timestamp: Time.zone.now,
            id: auth.id,
          }
          redirect_to main_app.new_user_session_path(pending: 1)
        end
      end
    end
end
