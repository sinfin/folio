# frozen_string_literal: true

require "test_helper"

class Folio::Devise::Omniauth::AuthenticationsControllerTest < Folio::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "destroy" do
    create_and_host_site

    user = create(:folio_user)
    auth = create_omniauth_authentication
    auth.update!(user:)

    delete folio.devise_omniauth_authentication_path(provider: "facebook")
    assert_redirected_to new_user_session_path

    sign_in user
    assert_difference("Folio::Omniauth::Authentication.count", -1) do
      delete folio.devise_omniauth_authentication_path(provider: "facebook")
      assert_redirected_to main_app.send(Rails.application.config.folio_users_after_sign_in_path)
    end
  end
end
