# frozen_string_literal: true

require "test_helper"

class Folio::Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    create(:folio_site)

    @params = {
      email: "email@email.email",
      password: "password",
    }

    @user = create(:folio_user, @params)
  end

  test "new" do
    get main_app.new_user_session_path
    assert_response(:ok)
  end

  test "create" do
    post main_app.user_session_path, params: { user: @params }
    assert_redirected_to main_app.send(Rails.application.config.folio_users_after_sign_in_path)
  end

  test "ajax create" do
    post main_app.user_session_path(format: :json), params: { user: @params }
    assert_response(:ok)
  end

  test "destroy" do
    sign_in @user
    get main_app.destroy_user_session_path
    assert_redirected_to main_app.new_user_session_path
  end

  if Rails.application.config.folio_users_omniauth_providers.present?
    test "pending" do
      user = create(:folio_user)
      auth = create_omniauth_authentication(user.email, "foo")

      assert_not auth.find_or_create_user!

      get main_app.new_user_session_path(pending: 1)
      assert_select ".f-devise-omniauth-conflict", false

      do_omniauth_callback(auth)

      get main_app.new_user_session_path(pending: 1)
      assert_select ".f-devise-omniauth-conflict"
    end

    test "conflict_token" do
      user = create(:folio_user)
      auth = create_omniauth_authentication(user.email, "foo")

      assert_not auth.find_or_create_user!
      assert_equal(user.id, auth.reload.conflict_user_id)

      get main_app.new_user_session_path(conflict_token: "foo")
      assert_redirected_to main_app.new_user_session_path

      assert_nil(auth.reload.folio_user_id)

      get main_app.new_user_session_path(conflict_token: auth.conflict_token)
      assert_redirected_to main_app.send(Rails.application.config.folio_users_after_sign_in_path)

      assert_equal(user.id, auth.reload.folio_user_id)
    end

    def do_omniauth_callback(auth)
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:facebook] = omniauth_authentication_openstruct(auth.email, auth.nickname)

      get user_facebook_omniauth_callback_url, headers: { "omniauth.auth" => OmniAuth.config.mock_auth[:facebook] }
    end
  end
end
