# frozen_string_literal: true

require "test_helper"

class Folio::Users::InvitationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "new" do
    skip unless Rails.application.config.folio_users_publicly_invitable

    create_and_host_site

    get main_app.new_user_invitation_path
    assert_response(:ok)

    sign_in create(:folio_user)
    get main_app.new_user_invitation_path
    assert_response(302)
  end

  test "create" do
    skip unless Rails.application.config.folio_users_publicly_invitable

    create_and_host_site

    assert_difference("Folio::User.count", 1) do
      post main_app.user_invitation_path, params: {
        user: {
          email: "email@email.email"
        }
      }
    end

    sign_in create(:folio_user)

    assert_difference("Folio::User.count", 0) do
      post main_app.user_invitation_path, params: {
        user: {
          email: "another-email@email.email"
        }
      }
    end

    assert_response(302)
  end

  test "edit" do
    create_and_host_site
    user = Folio::User.invite!(email: "email@email.email")
    get main_app.accept_user_invitation_path(invitation_token: user.raw_invitation_token)
    assert_response(:ok)
  end

  test "update" do
    create_and_host_site

    user = Folio::User.invite!(email: "email@email.email",
                               first_name: "a",
                               last_name: "b")
    assert_not user.invitation_accepted?

    put main_app.user_invitation_path, params: {
      user: {
        invitation_token: user.raw_invitation_token,
        password: "New@Password.123",
        password_confirmation: "New@Password.123",
        primary_address_attributes: {
          address_line_1: "address_line_1",
          address_line_2: "address_line_2",
          city: "city",
          zip: "zip",
          country_code: "country_code",
        }
      }
    }

    assert_redirected_to main_app.send(Rails.application.config.folio_users_after_accept_path)
    assert user.reload.invitation_accepted?
  end

  test "show" do
    skip unless Rails.application.config.folio_users_publicly_invitable

    create_and_host_site

    get main_app.user_invitation_path
    # redirect without :folio_user_invited_email in session
    assert_redirected_to main_app.new_user_invitation_path

    assert_difference("Folio::User.count", 1) do
      post main_app.user_invitation_path, params: {
        user: {
          email: "email@email.email"
        }
      }
    end

    assert_redirected_to main_app.user_invitation_path
    follow_redirect!

    # render with :folio_user_invited_email in session
    assert_select ".f-devise-invitations-show"
  end
end
