# frozen_string_literal: true

require "test_helper"

class Folio::Users::OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    super
    create(:folio_site)
  end

  test "bind_user_and_redirect - signed in" do
    # should add the authentication to current user
    user = create(:folio_user)
    sign_in user

    assert_difference("user.authentications.count", 1) do
      get main_app.user_facebook_omniauth_callback_path
    end
  end

  test "bind_user_and_redirect - signed out - no conflict" do
    # should go to /users/auth/new_user and prompt user creation
    assert_difference("Folio::User.count", 0) do
      assert_difference("Folio::Omniauth::Authentication.count", 1) do
        get main_app.user_facebook_omniauth_callback_path
        assert_redirected_to users_auth_new_user_path
      end
    end
  end

  test "bind_user_and_redirect - signed out - conflict" do
    # should set conflict info to session and go to /users/auth/conflict
    user = create(:folio_user, email: "omniauth@authentication.com")

    assert_difference("Folio::User.count", 0) do
      assert_difference("Folio::Omniauth::Authentication.count", 1) do
        get main_app.user_facebook_omniauth_callback_path
        assert_redirected_to users_auth_conflict_path
      end
    end
  end

  test "new_user without session data" do
    # redirect to sign_in with a flash message
    get main_app.users_auth_new_user_path
    assert_redirected_to main_app.new_user_session_path
  end

  test "new_user with session data" do
    get main_app.user_facebook_omniauth_callback_path
    assert_redirected_to main_app.users_auth_new_user_path

    get main_app.users_auth_new_user_path
    assert_response :ok
  end

  test "create_user without session data" do
    assert_difference("Folio::User.count", 0) do
      post main_app.users_auth_create_user_path, params: {
        user: {
          email: "email@email.email",
          first_name: "Foo",
          last_name: "Bar",
        }
      }
      assert_redirected_to main_app.new_user_session_path
    end
  end

  test "create_user with session data - valid" do
    get main_app.user_facebook_omniauth_callback_path
    assert_redirected_to main_app.users_auth_new_user_path

    assert_difference("Folio::User.count", 1) do
      post main_app.users_auth_create_user_path, params: {
        user: {
          email: "email@email.email",
          first_name: "Foo",
          last_name: "Bar",
        }
      }
      assert_redirected_to "/"

      user = Folio::User.order(id: :desc).first
      assert_equal "email@email.email", user.email
      assert_equal 1, user.authentications.count
    end
  end

  test "create_user with session data - invalid" do
    get main_app.user_facebook_omniauth_callback_path
    assert_redirected_to main_app.users_auth_new_user_path

    assert_difference("Folio::User.count", 0) do
      post main_app.users_auth_create_user_path, params: {
        user: {
          email: "invalid",
          first_name: "Foo",
          last_name: "Bar",
        }
      }
      assert_response(:ok)
    end
  end

  test "create_user with session data - email of an existing user" do
    user = create(:folio_user)

    get main_app.user_facebook_omniauth_callback_path
    assert_redirected_to main_app.users_auth_new_user_path

    assert_difference("Folio::User.count", 0) do
      post main_app.users_auth_create_user_path, params: {
        user: {
          email: user.email,
          first_name: "Foo",
          last_name: "Bar",
        }
      }
      assert_response(:ok)
    end
  end
end
