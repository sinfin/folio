# frozen_string_literal: true

class Folio::Users::EmailLogin::WaitingComponent < Folio::ApplicationComponent
  def initialize(email:, state:, expires_at:, resend_at:, trust_browser: true)
    @email = email
    @state = state
    @expires_at = expires_at
    @resend_at = resend_at
    @trust_browser = trust_browser
  end

  private
    def waiting?
      %w[waiting approved].include?(@state)
    end

    def resend_disabled?
      @state != "waiting" || @resend_at > Time.current.to_f
    end

    def data
      stimulus_controller("f-users-email-login-waiting",
                          values: { status_url: controller.main_app.status_user_email_login_path(format: :json),
                                    state: @state, expires_at: @expires_at, resend_at: @resend_at,
                                    trust_storage_key: "folio.emailLogin.trust.#{Digest::SHA256.hexdigest("#{@email}:#{@expires_at}")}",
                                    expired_message: t("folio.users.email_login.expired"),
                                    invalid_message: t("folio.users.email_login.invalid"),
                                    waiting_message: t("folio.users.email_login.waiting"),
                                    connection_error_message: t("folio.users.email_login.connection_error") },
                          action: { "visibilitychange@document" => "visibilityChanged",
                                    "pagehide@window" => "stop", "pageshow@window" => "pageShown",
                                    "turbolinks:before-cache@document" => "stop" })
    end

    def message
      key = @state == "expired" ? "expired" : (waiting? ? "waiting" : "invalid")
      t("folio.users.email_login.#{key}")
    end

    def completion_form_data
      stimulus_target("completionForm")
    end

    def status_data
      stimulus_target("status")
    end

    def trust_browser_data
      stimulus_data(target: "trustBrowser", action: { change: "saveBrowserTrust" })
    end

    def resend_data
      stimulus_target("resend")
    end
end
