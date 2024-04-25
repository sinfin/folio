# frozen_string_literal: true

require "test_helper"

class Folio::UsersTest < Folio::Console::BaseControllerTest
  attr_reader :auth_allowed_user, :auth_forbidden_user

  def setup
    Folio::Current.original_reset
    create_and_host_site
    @auth_allowed_user = create(:folio_user, password: "password")
    @auth_forbidden_user = create(:folio_user, password: "password")
    create(:folio_site_user_link, site: @site, locked_at: Time.current, user: auth_forbidden_user)
 end

  test "sign_in dis/allowed" do
    assert_not_equal auth_allowed_user.email, auth_forbidden_user.email

    post user_session_url(params: { user: { email: auth_allowed_user.email, password: "password" } })

    assert_redirected_to root_url
    follow_redirect!
    assert_select ".d-ui-flash", text: "Přihlášení proběhlo úspěšně."
    assert_select ".user_email", text: "E-mail#{auth_allowed_user.email}"

    get destroy_user_session_url

    assert_redirected_to new_user_session_url
    follow_redirect!
    assert_select ".d-ui-flash", text: "Odhlášení proběhlo úspěšně."

    post user_session_url(params: { user: { email: auth_forbidden_user.email, password: "password" } })

    assert_redirected_to new_user_session_url
    follow_redirect!
    assert_select ".d-ui-flash", text: "Váš účet byl zablokován. Prosím kontaktujte správce."
    assert_select ".user_email", text: "E-mail#{auth_forbidden_user.email}", count: 0
  end

  test "correct tab in console/users" do
    superadmin = create(:folio_user, :superadmin)
    sign_in superadmin

    get console_users_url

    assert_response :success
    skip "not yet implemented"

    assert_select ".folio-console-users-tab", text: "Active"
    assert_select ".folio-console-users__user_mail", text: @auth_allowed_user.email

    get console_users_url(tab: "locked")

    assert_select ".folio-console-users-tab", text: "Locked"
    assert_select ".folio-console-users__user_mail", text: @auth_forbidden_user.email

    get console_users_url(tab: "active")

    assert_select ".folio-console-users-tab", text: "Active"
    assert_select ".folio-console-users__user_mail", text: @auth_allowed_user.email
  end
end
