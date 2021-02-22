# frozen_string_literal: true

class Folio::Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Folio::Users::DeviseUserPaths

  def facebook
    bind_user_and_redirect(root_url)
  end

  def twitter
    bind_user_and_redirect(root_url)
  end

  def google_oauth2
    bind_user_and_redirect(root_url)
  end

  private
    def bind_user_and_redirect(fallback_url)
      auth = Folio::Omniauth::Authentication.from_request(request)

      if user_signed_in?
        target_url = stored_location_for(:user).presence || fallback_url

        if auth.user.nil?
          # it's a new Authentication
          auth.user = current_user
          auth.save!

          redirect_to target_url
        else
          redirect_to target_url
        end
      else
        if user = auth.find_or_create_user!
          sign_in_and_redirect user
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
