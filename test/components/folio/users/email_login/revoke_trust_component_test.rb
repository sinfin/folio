# frozen_string_literal: true

require "test_helper"

class Folio::Users::EmailLogin::RevokeTrustComponentTest < Folio::ComponentTest
  test "revocation is hidden when the feature is disabled" do
    render_inline(Folio::Users::EmailLogin::RevokeTrustComponent.new)

    assert_no_selector ".f-users-email-login-revoke-trust"
  end

  test "enabled feature offers a form for revoking all browser trust" do
    Rails.application.config.stub(:folio_users_email_login_verification_enabled, true) do
      render_inline(Folio::Users::EmailLogin::RevokeTrustComponent.new)
    end

    assert_selector "form[method='post'][action='/users/email_login/revoke_trusted_browsers']"
    assert_selector "input[name='_method'][value='delete']", visible: :all
    assert_selector "button[type='submit']", text: I18n.t("folio.users.email_login.revoke")
  end
end
