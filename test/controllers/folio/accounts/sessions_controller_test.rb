# frozen_string_literal: true

require "test_helper"

class Folio::Accounts::SessionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    create_and_host_site
    @params = {
      email: "email@email.email",
      password: "Complex@Password.123",
    }

    @admin = create(:folio_user, :superadmin, @params)
  end

  test "sign_in redirect to request page" do
    get folio.edit_console_site_path
    assert_redirected_to new_user_session_path
    follow_redirect!
    post user_session_path, params: { user: @params }
    assert_redirected_to folio.edit_console_site_path
  end

  test "sign_in redirect to site root" do
    post user_session_path, params: { user: @params }
    assert_redirected_to root_path
  end

  test "sign_out redirect to sign_in page" do
    sign_in @admin
    get destroy_user_session_path
    assert_redirected_to new_user_session_path
  end
end
