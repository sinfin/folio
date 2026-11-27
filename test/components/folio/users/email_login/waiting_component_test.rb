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

  test "progress spinner and continue button wait hidden for the script" do
    render_inline(Folio::Users::EmailLogin::WaitingComponent.new(email: "user@example.test", state: "waiting",
                                                              expires_at: 10.minutes.from_now.to_f,
                                                              resend_at: 60.seconds.from_now.to_f))

    assert_selector "[data-f-users-email-login-waiting-target='spinner'][aria-hidden='true'][hidden] .folio-loader",
                    visible: :all
    assert_selector "button[type='button'][hidden][data-f-users-email-login-waiting-target='continue']",
                    text: I18n.t("folio.users.email_login.continue"), visible: :all
    assert_includes rendered_content, I18n.t("folio.users.email_login.completing")
  end

  test "password confirmations may use any device while magic links stay in this browser" do
    render_inline(Folio::Users::EmailLogin::WaitingComponent.new(email: "user@example.test", state: "waiting",
                                                              expires_at: 10.minutes.from_now.to_f,
                                                              resend_at: 60.seconds.from_now.to_f))
    assert_text I18n.t("folio.users.email_login.cross_device_instruction")

    render_inline(Folio::Users::EmailLogin::WaitingComponent.new(email: "user@example.test", state: "waiting",
                                                              expires_at: 10.minutes.from_now.to_f,
                                                              resend_at: 60.seconds.from_now.to_f, magic_link: true))
    assert_text I18n.t("folio.users.email_login.magic_link_instruction")
    assert_no_text I18n.t("folio.users.email_login.cross_device_instruction")
  end

  test "the code field below the instruction submits to the code endpoint first" do
    render_inline(Folio::Users::EmailLogin::WaitingComponent.new(email: "user@example.test", state: "waiting",
                                                              expires_at: 10.minutes.from_now.to_f,
                                                              resend_at: 60.seconds.from_now.to_f, magic_link: true))

    input = page.find("input[name='email_login_code']")
    assert_equal "text", input[:type]
    assert_equal "numeric", input[:inputmode]
    assert_equal "one-time-code", input[:autocomplete]
    assert_nil input[:pattern]
    assert_nil input[:required]
    assert_equal "email-login-code-error email-login-code-hint", input["aria-describedby"]
    assert_selector "label[for='email-login-code']", text: I18n.t("folio.users.email_login.code_label")
    assert_selector "#email-login-code-error[role='alert'][hidden]", visible: :all
    submits = page.all("form[action='/users/email_login/complete'] input[type='submit']", visible: :all)
    assert_equal "/users/email_login/verify_code", submits.first[:formaction]
    assert_equal I18n.t("folio.users.email_login.code_submit"), submits.first[:value]
    assert_operator rendered_content.index(I18n.t("folio.users.email_login.magic_link_instruction")), :<,
                    rendered_content.index("email_login_code")
  end

  test "a code error is shown at the field" do
    render_inline(Folio::Users::EmailLogin::WaitingComponent.new(email: "user@example.test", state: "waiting",
                                                              expires_at: 10.minutes.from_now.to_f,
                                                              resend_at: 60.seconds.from_now.to_f,
                                                              code_error: "Wrong code"))

    assert_selector "input[name='email_login_code'].is-invalid[aria-invalid='true'][autofocus]"
    assert_selector "#email-login-code-error[role='alert']", text: "Wrong code"
  end

  test "expired attempts cannot be completed or resent" do
    render_inline(Folio::Users::EmailLogin::WaitingComponent.new(email: "user@example.test", state: "expired",
                                                              expires_at: 1.second.ago.to_f, resend_at: 1.minute.ago.to_f,
                                                              trust_browser: false))

    assert_selector "[role='status']", text: I18n.t("folio.users.email_login.expired")
    assert_selector "input[type='submit'][disabled]", count: 3
    assert_selector "input[name='email_login_code'][disabled]"
    assert_no_selector "input[name='trust_browser'][checked]"
  end
end
