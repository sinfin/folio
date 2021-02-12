# frozen_string_literal: true

require "test_helper"

class Folio::Users::PasswordsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    create(:folio_site)
  end

  test "new" do
    get new_user_password_path
    assert_response(:ok)
  end

  test "create" do
    user = create(:folio_user)
    assert_not user.reset_password_token
    post user_password_path, params: { user: { email: user.email } }
    assert_redirected_to new_user_session_path

    user.reload
    assert user.reset_password_token
  end

  test "edit" do
    user = create(:folio_user)
    raw = user.send_reset_password_instructions

    user.reload
    get edit_user_password_path(reset_password_token: raw)
    assert_response(:ok)
  end

  test "update" do
    user = create(:folio_user)
    raw = user.send_reset_password_instructions

    put user_password_path, params: {
      user: {
        reset_password_token: raw,
        password: "new-password",
        password_confirmation: "new-password",
      }
    }
    assert_redirected_to root_path

    user.reload

    assert user.last_sign_in_at
  end
end
