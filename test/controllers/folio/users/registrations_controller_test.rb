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
end
