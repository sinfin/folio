# frozen_string_literal: true

require "test_helper"

class Folio::Console::PagesControllerTest < Folio::Console::BaseControllerTest
  class AuditedPage < Folio::Page
    include Folio::Audited::Model
    audited

    def audited_console_restorable?
      title != "non-restorable"
    end
  end

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

  test "show" do
    page = create(:folio_page)
    get url_for([:console, page])
    assert_redirected_to url_for([:edit, :console, page])
  end

  test "update" do
    page = create(:folio_page)
    assert_not_equal "foo", page.title

    patch url_for([:console, page]), params: { page: { title: "foo" } }
    assert_response :redirect

    assert_equal "foo", page.reload.title
  end

  test "update json" do
    page = create(:folio_page)
    assert_not_equal "foo", page.title

    patch url_for([:console, page, format: :json]), params: { page: { title: "foo" } }
    assert_response :success

    assert_equal "foo", page.reload.title
    assert_equal "foo", response.parsed_body["data"]["title"]
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
    page = Audited.stub(:auditing_enabled, true) {  create(:folio_page) }

    get url_for([:revision, :console, page, version: 1])

    assert_response :success
  end

  test "restore" do
    page = Audited.stub(:auditing_enabled, true) {  create(:folio_page) }

    post url_for([:restore, :console, page, version: 1])

    assert_redirected_to url_for([:edit, :console, page])
  end

  test "restore when not allowed" do
    page = Audited.stub(:auditing_enabled, true) do
      page = AuditedPage.create!(title: "non-restorable", site: get_any_site)

      assert_raises(ActionController::BadRequest) do
        post url_for([:restore, :console, page, version: 1])
      end
    end
  end

  test "new_clone when enabled" do
    Rails.application.config.stub(:folio_console_clonable_enabled, true) do
      page = create(:folio_page)
      get url_for([:new_clone, :console, page])
      assert_response :success
    end
  end

  test "new_clone when disabled" do
    Rails.application.config.stub(:folio_console_clonable_enabled, false) do
      page = create(:folio_page)
      get url_for([:new_clone, :console, page])
      assert_redirected_to url_for([:console, page.class])
    end
  end
end
