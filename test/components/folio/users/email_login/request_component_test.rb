# frozen_string_literal: true

require "test_helper"

class Folio::Users::EmailLogin::RequestComponentTest < Folio::ComponentTest
  test "email entry has no password or code input and preserves the password option" do
    render_inline(Folio::Users::EmailLogin::RequestComponent.new(user: Folio::User.new))

    assert_selector "form[method='post'][action='/users/email_login']"
    assert_selector "input[type='email'][name='user[email]']"
    assert_no_selector "input[name='user[remember_me]']"
    assert_selector "a[href='/users/sign_in']"
    assert_no_selector "input[type='password'], input[autocomplete='one-time-code']"
  end
end
