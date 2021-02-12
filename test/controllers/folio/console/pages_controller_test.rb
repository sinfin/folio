# frozen_string_literal: true

require "test_helper"

class Folio::Console::PagesControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Folio::Page])
    assert_response :success
  end

  test "new" do
    get url_for([:console, Folio::Page, action: :new])
    assert_response :success
  end

  test "edit" do
    page = create(:folio_page)
    get url_for([:edit, :console, page])
    assert_response :success
  end

  test "failed edit" do
    folio_page = create(:folio_page)

    visit url_for([:edit, :console, folio_page])
    page.fill_in "page_title", with: ""
    page.find('input[type="submit"]').click

    title_group = page.find(".form-group.page_title")
    assert title_group[:class].include?("form-group-invalid")
    assert_not page.has_css?(".alert-success")

    page.find('input[type="submit"]').click

    title_group = page.find(".form-group.page_title")
    assert title_group[:class].include?("form-group-invalid")
    assert_not page.has_css?(".alert-success")

    page.fill_in "page_title", with: "foo"
    page.find('input[type="submit"]').click
    assert page.has_css?(".alert-success")
  end

  test "revision" do
    page = create(:folio_page)
    get url_for([:revision, :console, page, version: 1])
    assert_response :success
  end

  test "revive" do
    page = create(:folio_page)
    post url_for([:restore, :console, page, version: 1])
    assert_redirected_to url_for([:edit, :console, page])
  end
end
