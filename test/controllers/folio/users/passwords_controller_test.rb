# frozen_string_literal: true

require "test_helper"

class Folio::Users::PasswordsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    create(:folio_site)
  end

  test "new" do
    get main_app.new_user_password_path
    assert_response(:ok)
  end

  test "create" do
    user = create(:folio_user)
    assert_not user.reset_password_token
    post main_app.user_password_path, params: { user: { email: user.email } }
    assert_redirected_to main_app.new_user_session_path

    user.reload
    assert user.reset_password_token
  end

  test "edit" do
    user = create(:folio_user)
    raw = user.send_reset_password_instructions

    user.reload
    get main_app.edit_user_password_path(reset_password_token: raw)
    assert_response(:ok)
  end

  test "update" do
    user = create(:folio_user)
    raw = user.send_reset_password_instructions

    put main_app.user_password_path, params: {
      user: {
        reset_password_token: raw,
        password: "new-password",
        password_confirmation: "new-password",
      }
    }

    if Devise.sign_in_after_reset_password
      assert_redirected_to main_app.send(Rails.application.config.folio_users_after_sign_in_path)
    else
      assert_redirected_to main_app.new_user_session_path
    end

    user.reload

    assert user.last_sign_in_at
  end
end
