# frozen_string_literal: true

require "test_helper"

class Folio::Console::MergesControllerTest < Folio::Console::BaseControllerTest
  include Folio::Engine.routes.url_helpers

  test "new" do
    original = create(:folio_page)
    duplicate = create(:folio_page)

    visit new_console_merge_path("Folio::Page", original, duplicate)
    assert page.has_css?(".f-c-merges-form__form")
    assert_not page.has_css?(".f-c-merges-form__invalid")
  end

  test "new - invalid" do
    original = create(:folio_page)
    duplicate = create(:folio_page)
    original.update_column(:title, nil)
    assert_not(original.valid?)

    visit new_console_merge_path("Folio::Page", original, duplicate)
    assert_not page.has_css?(".f-c-merges-form__form")
    assert page.has_css?(".f-c-merges-form__invalid")
  end

  test "create" do
    original = create(:folio_page, title: "foo")
    duplicate = create(:folio_page, title: "bar")

    post console_merge_path("Folio::Page", original, duplicate), params: {
      merge: {
        title: Folio::Merger::DUPLICATE,
      }
    }
    assert_redirected_to url_for([:edit, :console, original])

    assert_equal("bar", original.reload.title)
    assert_not(Folio::Page.exists?(id: duplicate.id))
  end

  test "redirects to given url on success" do
    original = create(:folio_page, title: "foo")
    duplicate = create(:folio_page, title: "bar")

    url = "/foo/bar/baz"
    post console_merge_path("Folio::Page", original, duplicate, url: url), params: {
      merge: {
        title: Folio::Merger::DUPLICATE,
      }
    }
    assert_redirected_to url
  end

  test "original == duplicate" do
    original = create(:folio_page, title: "foo")

    url = "/foo/bar/baz"
    get new_console_merge_path("Folio::Page", original, original, url: url)
    assert_redirected_to console_pages_path
  end
end
