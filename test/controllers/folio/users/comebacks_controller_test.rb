# frozen_string_literal: true

require "test_helper"

class Folio::Users::ComebacksControllerTest < ActionDispatch::IntegrationTest
  test "show" do
    create_and_host_site

    get folio.users_comeback_path, params: { to: main_app.new_user_session_path }, headers: { "HTTP_REFERER" => "/foo" }

    assert_redirected_to main_app.new_user_session_path

    create(:folio_user, password: "Complex@Password.123", email: "test@test.test")

    post main_app.user_session_path, params: {
      'user[email]': "test@test.test",
      'user[password]': "Complex@Password.123"
    }

    # Get there after sign in
    assert_redirected_to "/foo"
  end

  test "show without to redirects to the root" do
    create_and_host_site

    get folio.users_comeback_path

    assert_redirected_to main_app.root_path
  end

  test "show with an external to redirects to the root" do
    create_and_host_site

    get folio.users_comeback_path, params: { to: "https://example.com/" }

    assert_redirected_to main_app.root_path
  end
end
