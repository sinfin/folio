# frozen_string_literal: true

class Folio::Users::EmailLogin::WaitingComponent < Folio::ApplicationComponent
  CODE_INPUT_ID = "email-login-code"
  CODE_ERROR_ID = "email-login-code-error"
  CODE_HINT_ID = "email-login-code-hint"

  def initialize(email:, state:, expires_at:, resend_at:, trust_browser: true, magic_link: false, code_error: nil)
    @email = email
    @state = state
    @expires_at = expires_at
    @resend_at = resend_at
    @trust_browser = trust_browser
    @magic_link = magic_link
    @code_error = code_error
  end

  private
    def instruction
      t("folio.users.email_login.#{@magic_link ? "magic_link_instruction" : "cross_device_instruction"}")
    end

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
                                    completing_message: t("folio.users.email_login.completing"),
                                    connection_error_message: t("folio.users.email_login.connection_error"),
                                    code_url: controller.main_app.verify_code_user_email_login_path(format: :json),
                                    code_format_message: t("folio.users.email_login.code_format"),
                                    code_error_message: t("folio.users.email_login.code_error") },
                          action: { "visibilitychange@document" => "visibilityChanged",
                                    "pagehide@window" => "stop", "pageshow@window" => "pageShown",
                                    "turbolinks:before-cache@document" => "stop" })
    end

    def message
      key = @state == "expired" ? "expired" : (waiting? ? "waiting" : "invalid")
      t("folio.users.email_login.#{key}")
    end

    def code_input_aria
      { describedby: "#{CODE_ERROR_ID} #{CODE_HINT_ID}", invalid: ("true" if @code_error) }.compact
    end

    def code_input_data
      stimulus_merge_data(stimulus_target("codeInput"), stimulus_action(input: "hideCodeError"))
    end

    def code_submit_data
      stimulus_target("codeSubmit")
    end

    def code_error_data
      stimulus_target("codeError")
    end

    def completion_form_data
      stimulus_merge_data(stimulus_target("completionForm"), stimulus_action(submit: "submitCode"))
    end

    def status_data
      stimulus_target("status")
    end

    def spinner_data
      stimulus_target("spinner")
    end

    def continue_data
      stimulus_merge_data(stimulus_target("continue"), stimulus_action(click: "continueSignIn"))
    end

    def trust_browser_data
      stimulus_data(target: "trustBrowser", action: { change: "saveBrowserTrust" })
    end

    def resend_data
      stimulus_target("resend")
    end
end
