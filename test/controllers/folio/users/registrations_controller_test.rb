# frozen_string_literal: true

require "test_helper"

class Folio::Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    create(:folio_site)

    @params = {
      email: "email@email.email",
      password: "Complex@Password.123",
      first_name: "Name",
      last_name: "Surname",
    }

    @user = create(:folio_user, @params)
  end

  test "new" do
    get main_app.new_user_registration_path
    assert_response(:ok)
  end

  test "create" do
    post main_app.user_registration_path, params: { user: @params.merge(email: "other@email.email") }
    assert_redirected_to main_app.send(Rails.application.config.folio_users_after_sign_up_path)
    assert Folio::User.exists?(email: "other@email.email")
  end

  test "create_invalid" do
    post main_app.user_registration_path, params: {
      user: {
        email: "third@email.email",
        password: "Complex@Password.123",
      }
    }
    assert_not Folio::User.exists?(email: "third@email.email")
    assert_response(:ok)
  end

  test "edit" do
    sign_in @user
    get main_app.edit_user_registration_path
    assert_response(:ok)
  end

  test "update" do
    sign_in @user
    patch main_app.user_registration_path, params: {
      user: {
        email: "new@email.email",
      }
    }
    assert_response(:ok)
    assert_not_equal("new@email.email", @user.reload.email)

    sign_in @user
    patch main_app.user_registration_path, params: {
      user: {
        email: "new@email.email",
        current_password: "Complex@Password.123",
      }
    }
    assert_redirected_to main_app.send(Rails.application.config.folio_users_after_sign_in_path)
    assert_equal("new@email.email", @user.reload.email)
  end

  test "destroy" do
    assert_equal(1, Folio::User.count)
    sign_in @user
    delete main_app.user_registration_path
    assert_redirected_to main_app.send(Rails.application.config.folio_users_after_sign_out_path)
    assert_equal(0, Folio::User.count)
  end
end
