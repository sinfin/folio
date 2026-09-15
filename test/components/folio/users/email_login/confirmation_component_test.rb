# frozen_string_literal: true

require "test_helper"

class Folio::Users::EmailLogin::ConfirmationComponentTest < Folio::ComponentTest
  test "email approval requires an explicit form submission after preparation" do
    site = create_site(force: true)
    challenge = Folio::Users::EmailLoginChallenge.new(site:, created_at: Time.current)
    render_inline(Folio::Users::EmailLogin::ConfirmationComponent.new(challenge:))

    assert_selector "form[method='post'][action='/users/email_login/approve']"
    assert_selector "button[type='submit']", text: I18n.t("folio.users.email_login.confirm")
    assert_no_selector "script, [data-controller], input[name='email_login_token']"
    assert_includes rendered_content, site.title
  end

  test "approval explains that the original browser will sign in" do
    render_inline(Folio::Users::EmailLogin::ConfirmationComponent.new(approved: true))

    assert_text I18n.t("folio.users.email_login.approved_instruction")
    assert_no_selector "form, script"
  end

  test "invalid link offers starting again" do
    render_inline(Folio::Users::EmailLogin::ConfirmationComponent.new(invalid: true))

    assert_text I18n.t("folio.users.email_login.invalid")
    assert_selector "a[href='/users/sign_in']"
    assert_no_selector "form, script"
  end
end
