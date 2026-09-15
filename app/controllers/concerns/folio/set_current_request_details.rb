# frozen_string_literal: true

module Folio::SetCurrentRequestDetails
  extend ActiveSupport::Concern

  included do
    prepend_before_action :set_up_current_from_request
    rescue_from "Folio::Devise::EmailLogin::Unavailable", with: :render_email_login_unavailable
  end

  private
    def render_email_login_unavailable
      if request.format.json?
        render json: { error: I18n.t("folio.users.email_login.unavailable") }, status: :service_unavailable
      else
        render plain: I18n.t("folio.users.email_login.unavailable"), status: :service_unavailable
      end
    end

    def set_up_current_from_request
      if Folio::Current.request_id.nil? || (request && request.uuid != Folio::Current.request_id)
        # warden takes params from request, so we need to set source_site_id here,
        # before searching for current user
        if request.params["user"].present? && request.params["user"]["auth_site_id"].blank?
          # don't use `.site` here as that would try to fetch one without host and cache it
          request.params["user"]["auth_site_id"] = Folio::Current.get_site(host: request.host).id.to_s
        end

        # Password authentication must run in Sessions#create, after CAPTCHA.
        user = if Folio::Devise::EmailLogin.verification_enabled? &&
                  request.path_parameters[:controller].to_s.end_with?("/sessions") && request.path_parameters[:action] == "create"
          request.env["warden"].user(:user)
        else
          current_user
        end

        Folio::Current.setup!(request:,
                              user:,
                              session:,
                              site_cache_key_base: Rails.application.config.action_controller.perform_caching ? folio_current_site_cache_key_base : nil)
      end

      if request.env["folio.email_login.pending"] && request.env["folio.email_login.purpose"] == "rememberable"
        if request.format.json?
          render json: { data: { url: main_app.user_email_login_path } }, status: :unauthorized
        else
          redirect_to main_app.user_email_login_path, status: :see_other
        end
      end
    end

    def folio_current_site_cache_key_base
      @folio_current_site_cache_key_base ||= Rails.cache.fetch(["Folio::Current.site_cache_key_base", request.host], expires_in: 30.seconds) do
        [
          ENV["CURRENT_RELEASE_COMMIT_HASH"],
          request.host,
          Folio::Site.maximum(:updated_at)&.to_f,
          Folio::Site.count,
        ]
      end
    end
end
