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

    put url_for([:console, folio_page]), params: { page: { title: "" } }

    assert_select ".form-group.page_title.form-group-invalid"
    assert_select ".f-c-ui-alert--success", false

    put url_for([:console, folio_page]), params: { page: { title: "foo" } }

    assert_redirected_to url_for([:edit, :console, folio_page])
    follow_redirect!
    assert_select ".f-c-ui-alert--success"
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
