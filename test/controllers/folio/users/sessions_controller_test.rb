# frozen_string_literal: true

require "test_helper"

class Folio::Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    create_and_host_site

    @params = {
      email: "email@email.email",
      password: "Complex@Password.123",
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

  test "create pending invitation" do
    skip unless Rails.application.config.folio_users_publicly_invitable
    user = Folio::User.invite!(email: "invite@email.email")
    old_timestamp = user.invitation_created_at
    post main_app.user_session_path, params: { user: { email: "invite@email.email" } }
    assert_redirected_to user_invitation_path
    assert_not_equal old_timestamp, user.reload.invitation_created_at
  end

  test "ajax create pending invitation" do
    skip unless Rails.application.config.folio_users_publicly_invitable
    user = Folio::User.invite!(email: "invite@email.email")
    old_timestamp = user.invitation_created_at
    post main_app.user_session_path(format: :json), params: { user: { email: "invite@email.email" } }
    assert_response(:ok)
    assert_equal user_invitation_path, response.parsed_body["data"]["url"]
    assert_not_equal old_timestamp, user.reload.invitation_created_at
  end

  test "destroy" do
    sign_in @user
    get main_app.destroy_user_session_path
    assert_redirected_to main_app.send(Rails.application.config.folio_users_after_sign_out_path)
  end
end
