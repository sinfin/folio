# frozen_string_literal: true

require "test_helper"

class Folio::FriendlyIdAndSimpleFormTest < Folio::CapybaraTest
  test "changing slug should not change form URL" do
    sign_in_to_console_and_go_to_pages_index
    create(:folio_page, slug: "changing-slug-should-not-change-form-url")

    visit "/console/pages/changing-slug-should-not-change-form-url/edit"
    form = find(".f-c-simple-form-with-atoms")
    assert_equal "/console/pages/changing-slug-should-not-change-form-url", form[:action], "form action points to the slug saved in the database"

    fill_in "Název stránky", with: ""
    fill_in "Varianta názvu pro odkazy", with: "changing-slug-should-not-change-form-url-changed"
    find('[data-test-id="submit-button"]').click

    assert_current_path("/console/pages/changing-slug-should-not-change-form-url")
    assert page.has_css?(".invalid-feedback", text: "Název stránky je povinná položka")
    form = find(".f-c-simple-form-with-atoms")
    assert_equal "/console/pages/changing-slug-should-not-change-form-url", form[:action], "form action points to the slug saved in the database"

    fill_in "Název stránky", with: "should not break now"
    fill_in "Varianta názvu pro odkazy", with: "changing-slug-should-not-change-form-url-changed"
    find('[data-test-id="submit-button"]').click

    assert_current_path("/console/pages/changing-slug-should-not-change-form-url-changed/edit")
  end

  private
    def sign_in_to_console_and_go_to_pages_index
      @site = create_and_host_site

      @email = "test@test.test"
      @password = "Test@Test.123"
      @user = create(:folio_user, :superadmin, email: @email, password: @password)

      visit "/console"
      assert_current_path("/users/sign_in")

      assert page.has_css?("h1", text: "Přihlášení")

      within ".d-layout-main" do
        fill_in "E-mail", with: @email
        fill_in "Heslo", with: @password
        click_on "Přihlásit se"
      end

      visit "/console/pages"
      assert_current_path("/console/pages")
    end
end
