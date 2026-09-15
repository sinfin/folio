# frozen_string_literal: true

require "test_helper"

class Folio::Users::EmailLogin::WaitingComponentTest < Folio::ComponentTest
  test "waiting offers automatic completion and explicit manual actions with browser trust" do
    render_inline(Folio::Users::EmailLogin::WaitingComponent.new(email: "user@example.test", state: "waiting",
                                                              expires_at: 10.minutes.from_now.to_f,
                                                              resend_at: 60.seconds.from_now.to_f))

    assert_selector "[data-controller='f-users-email-login-waiting']"
    assert_selector "[role='status']", text: I18n.t("folio.users.email_login.waiting")
    assert_selector "form[method='post'][action='/users/email_login/complete']"
    assert_selector "input[type='checkbox'][name='trust_browser'][checked]"
    assert_selector "input[type='submit'][formaction='/users/email_login/resend']"
    assert_no_selector "input[type='password']"
    assert_includes rendered_content, "user@example.test"
  end

  test "expired attempts cannot be completed or resent" do
    render_inline(Folio::Users::EmailLogin::WaitingComponent.new(email: "user@example.test", state: "expired",
                                                              expires_at: 1.second.ago.to_f, resend_at: 1.minute.ago.to_f,
                                                              trust_browser: false))

    assert_selector "[role='status']", text: I18n.t("folio.users.email_login.expired")
    assert_selector "input[type='submit'][disabled]", count: 2
    assert_no_selector "input[name='trust_browser'][checked]"
  end
end
