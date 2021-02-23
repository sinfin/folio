# frozen_string_literal: true

require "test_helper"

class Folio::Users::InvitationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "new" do
    create(:folio_site)
    sign_in create(:folio_user)

    assert_raises(ActionController::MethodNotAllowed) do
      get main_app.new_user_invitation_path
    end
  end

  test "create" do
    create(:folio_site)
    sign_in create(:folio_user)


    assert_raises(ActionController::MethodNotAllowed) do
      post main_app.user_invitation_path, params: {
        user: {
          email: "email@email.email"
        }
      }
    end
  end

  test "edit" do
    create(:folio_site)
    user = Folio::User.invite!(email: "email@email.email")
    get main_app.accept_user_invitation_path(invitation_token: user.raw_invitation_token)
    assert_response(:ok)
  end

  test "update" do
    create(:folio_site)

    user = Folio::User.invite!(email: "email@email.email",
                               first_name: "a",
                               last_name: "b")
    assert_not user.invitation_accepted?

    put main_app.user_invitation_path, params: {
      user: {
        invitation_token: user.raw_invitation_token,
        password: "new-password",
        password_confirmation: "new-password",
      }
    }

    assert_redirected_to main_app.send(Rails.application.config.folio_users_after_accept_path)
    assert user.reload.invitation_accepted?
  end
end
