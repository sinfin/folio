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

  test "sign_in redirect to console root" do
    post user_session_path, params: { user: @params }
    assert_redirected_to root_path
  end

  test "sign_out redirect to sign_in page" do
    sign_in @user
    get destroy_user_session_path
    assert_redirected_to new_user_session_path
  end
end
