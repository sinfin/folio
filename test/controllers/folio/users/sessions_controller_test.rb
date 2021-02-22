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
    get new_user_session_path
    assert_response(:ok)
  end

  test "create" do
    post user_session_path, params: { user: @params }
    assert_redirected_to root_path
  end

  test "ajax create" do
    post user_session_path(format: :json), params: { user: @params }
    assert_response(:ok)
  end

  test "destroy" do
    sign_in @user
    get destroy_user_session_path
    assert_redirected_to new_user_session_path
  end

  test "pending" do
    auth = create_omniauth_authentication("foo@foo.foo", "foo")

    visit new_user_session_path(pending: 1)
    assert_not page.has_css?(".f-devise-omniauth-conflict")

    page.set_rack_session("pending_folio_authentication_id" => {
      timestamp: Time.zone.now,
      id: auth.id,
    })

    visit new_user_session_path(pending: 1)
    assert page.has_css?(".f-devise-omniauth-conflict")
  end

  test "conflict_token" do
    user = create(:folio_user)
    auth = create_omniauth_authentication(user.email, "foo")

    assert_not auth.find_or_create_user!
    assert_equal(user.id, auth.reload.conflict_user_id)

    get new_user_session_path(conflict_token: "foo")
    assert_redirected_to new_user_session_path

    assert_nil(auth.reload.folio_user_id)

    get new_user_session_path(conflict_token: auth.conflict_token)
    assert_redirected_to root_path

    assert_equal(user.id, auth.reload.folio_user_id)
  end
end
