# frozen_string_literal: true

require "test_helper"

class Folio::Console::CurrentUsersControllerTest < Folio::Console::BaseControllerTest
  test "show" do
    get folio.console_current_user_path
    assert_response(:ok)
    assert_select("h1", I18n.t("folio.console.current_users.show_component.title"))
  end

  test "update_email" do
    original_email = @superadmin.email

    assert_nil @superadmin.unconfirmed_email

    patch folio.update_email_console_current_user_path, params: {
      user: {
        email: "foo@bar.baz",
      }
    }
    assert_redirected_to(folio.console_current_user_path)

    @superadmin.reload

    assert_equal original_email, @superadmin.email
    assert_equal "foo@bar.baz", @superadmin.unconfirmed_email
  end

  test "update_password" do
    assert @superadmin.valid_password?("Complex@Password.123")

    assert_raises(ActionController::ParameterMissing) do
      patch folio.update_password_console_current_user_path
    end

    sign_in @superadmin
    patch folio.update_password_console_current_user_path, params: { user: {
      password: "Complex@Password.123456",
      password_confirmation: "Complex@Password.123456",
      current_password: "foo",
    } }
    assert_response(:ok)

    @superadmin.reload
    assert @superadmin.valid_password?("Complex@Password.123"), "Password should not be changed"
    assert_not @superadmin.valid_password?("Complex@Password.123456"), "Password should not be changed"

    sign_in @superadmin
    patch folio.update_password_console_current_user_path, params: { user: {
      password: "Complex@Password.123456",
      password_confirmation: "Complex@Password.123456",
      current_password: "Complex@Password.123",
    } }
    assert_redirected_to folio.console_current_user_path

    @superadmin.reload

    assert_not @superadmin.valid_password?("Complex@Password.123"), "Password should be changed"
    assert @superadmin.valid_password?("Complex@Password.123456"), "Password should be changed"
  end
end
