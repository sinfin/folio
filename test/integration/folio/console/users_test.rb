# frozen_string_literal: true

require "test_helper"

class Folio::UsersTest < Folio::Console::BaseControllerTest
  attr_reader :auth_allowed_user, :auth_forbidden_user

  def setup
    create_and_host_site
    @auth_allowed_user = create(:folio_user, password: "password")
    @auth_forbidden_user = create(:folio_user, password: "password")
    create(:folio_site_user_link, site: @site, locked_at: Time.current, user: auth_forbidden_user)

   # assert auth_allowed_user.active_for_authentication?

   # assert_not auth_forbidden_user.active_for_authentication?
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
    assert_select ".d-ui-flash", text: "Váš účet byl zamknutý. Prosím kontaktujte správce."
    assert_select ".user_email", text: "E-mail#{auth_forbidden_user.email}", count: 0
  end

  test "correct tab in console/users" do
  end
end
