# frozen_string_literal: true

require "test_helper"

class Folio::Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    create_and_host_site

    @password = "Complex@Password.123"

    @params = {
      email: "email@email.email",
      password: @password,
      first_name: "Name",
      last_name: "Surname",
    }

    @user = create(:folio_user, @params)
  end

  test "new" do
    assert_raises(NoMethodError) { main_app.new_user_registration_path }
  end

  test "edit_password" do
    get users_registrations_edit_password_path
    assert_redirected_to new_user_session_path

    sign_in create(:folio_user)
    get users_registrations_edit_password_path
    assert_response(:ok)
  end

  test "update_password" do
    user = create(:folio_user, email: "old@email.com", password: "Complex.Password.123")

    sign_in user

    patch users_registrations_update_password_path, params: {
      user: {
        password: "New.Password.123",
        password_confirmation: "New.Password.123",
        current_password: "bad",
      }
    }

    assert_response(:ok)

    user.update!(password: "Former.Password.123")
    sign_in user

    patch users_registrations_update_password_path, params: {
      user: {
        password: "New.Password.123",
        password_confirmation: "New.Password.123",
        current_password: "Former.Password.123",
      }
    }

    assert_redirected_to main_app.send(Rails.application.config.folio_users_after_password_change_path)
  end
end
