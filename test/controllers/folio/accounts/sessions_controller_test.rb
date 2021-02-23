# frozen_string_literal: true

require "test_helper"

class Folio::Accounts::SessionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    create(:folio_site)
    @params = {
      email: "email@email.email",
      password: "password",
    }

    @admin = create(:folio_admin_account, @params)
  end

  test "sign_in redirect to console root" do
    post account_session_path, params: { account: @params }
    assert_redirected_to folio.console_root_path
  end

  test "sign_out redirect to sign_in page" do
    sign_in @admin
    get destroy_account_session_path
    assert_redirected_to new_account_session_path
  end
end
