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
  end
end
