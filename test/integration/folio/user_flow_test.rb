# frozen_string_literal: true

require "test_helper"

class Folio::UserFlowTest < Folio::CapybaraTest
  test "standard via e-mail" do
    create_and_host_site

    visit main_app.new_user_invitation_url

    assert_difference("Folio::User.count", 1) do
      page.find(".f-devise--invitations-new .form-control").set "test@test.test"
      page.find(".f-devise--invitations-new [type=\"submit\"]").click
    end

    assert page.has_css?(".f-devise-invitations-show")

    user = Folio::User.order(id: :desc).first

    assert_equal "test@test.test", user.email
    assert_nil user.first_name
    assert_nil user.last_name
    assert_not user.invitation_accepted?

    assert_equal 1, user.site_user_links.count
    site_link = user.site_user_links.by_site(@site).first
    assert site_link.present?
    assert_equal [], site_link.roles

    # clicks the e-mail with the accept link
    user = Folio::User.invite!(email: "test@test.test")
    visit main_app.accept_user_invitation_url(invitation_token: user.raw_invitation_token)

    page.find('.f-devise--invitations-edit input[name="user[password]"]').set "Complex@Password.123"
    page.find('.f-devise--invitations-edit input[name="user[first_name]"]').set "First"
    page.find('.f-devise--invitations-edit input[name="user[last_name]"]').set "Last"

    page.find('.f-devise--invitations-edit input[name="user[primary_address_attributes][address_line_1]"]').set "Foo"
    page.find('.f-devise--invitations-edit input[name="user[primary_address_attributes][address_line_2]"]').set "1"
    page.find('.f-devise--invitations-edit input[name="user[primary_address_attributes][zip]"]').set "Foo"
    page.find('.f-devise--invitations-edit input[name="user[primary_address_attributes][city]"]').set "Foo"
    page.find('.f-devise--invitations-edit select[name="user[primary_address_attributes][country_code]"]').select "Itálie"

    page.find(".f-devise--invitations-edit [type=\"submit\"]").click

    user.reload

    assert user.invitation_accepted?
    assert_equal "test@test.test", user.email
    assert_equal "First", user.first_name
    assert_equal "Last", user.last_name

    assert user.primary_address
    assert_equal "Foo", user.primary_address.address_line_1
    assert_equal "1", user.primary_address.address_line_2
  end

  test "omniauth - new user" do
    skip "Skippinng: No Facebook Omniauth enabled" if (Rails.application.config.folio_users_omniauth_providers || []).exclude?(:facebook)

    create_and_host_site

    visit main_app.new_user_session_url(only_path: false)
    assert page.has_css?(".f-devise-omniauth__button .f-devise-omniauth-icon--facebook")

    # pretending authorization from Facebook
    # get main_app.user_facebook_omniauth_callback_path, env: { "omniauth.auth" => OmniAuth.config.mock_auth[:facebook] }
    page.driver.browser.header("omniauth.auth", OmniAuth.config.mock_auth[:facebook])

    visit main_app.user_facebook_omniauth_callback_url(only_path: false)

    # assert_redirected_to main_app.users_auth_new_user_path
    # follow_redirect! # asking user to create an account, serving data from Facebook
    page.has_css?("h1", text: "Dokončení registrace")
    within(".f-devise-resource-form .user_email") do
      page.has_css?("label", text: "E-mail (slouží pro přihlášení) ")
      assert_equal OMNIAUTH_AUTHENTICATION_DEFAULT_TEST_EMAIL, find_field("user[email]").value
    end

    assert_difference("Folio::User.count", 1) do
      click_on "Dokončit registraci"
      # assert_redirected_to main_app.send(Rails.application.config.folio_users_after_sign_in_path)
    end

    user = Folio::User.find_by(email: OMNIAUTH_AUTHENTICATION_DEFAULT_TEST_EMAIL)
    assert user.present?
    assert_equal "Lorem", user.first_name
    assert_equal "ipsum", user.last_name

    assert_equal 1, user.site_user_links.count
    site_link = user.site_user_links.by_site(@site).first
    assert site_link.present?
    assert_equal [], site_link.roles
  end
end
