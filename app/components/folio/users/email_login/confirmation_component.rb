# frozen_string_literal: true

class Folio::Users::EmailLogin::ConfirmationComponent < Folio::ApplicationComponent
  def initialize(challenge: nil, approved: false, invalid: false, preparing: false)
    @challenge = challenge
    @approved = approved
    @invalid = invalid
    @preparing = preparing
  end

  private
    def data
      return {} unless @preparing

      stimulus_controller("f-users-email-login-confirmation",
                          values: { url: controller.main_app.prepare_user_email_login_path(format: :json),
                                    connection_error: t("folio.users.email_login.prepare_error") })
    end

    def retry_data
      stimulus_merge_data(stimulus_target("retry"), stimulus_action(click: "prepare"))
    end
end
