# frozen_string_literal: true

require "test_helper"

class Folio::Console::EmailTemplatesControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Folio::EmailTemplate])
    assert_response :success
    create(:folio_email_template)
    get url_for([:console, Folio::EmailTemplate])
    assert_response :success
  end

  test "edit" do
    model = create(:folio_email_template)
    get url_for([:edit, :console, model])
    assert_response :success
  end

  test "update" do
    model = create(:folio_email_template)
    assert_not_equal("foo", model.title)
    put url_for([:console, model]), params: {
      email_template: {
        title: "foo",
      },
    }
    assert_redirected_to url_for([:edit, :console, model])
    assert_equal("foo", model.reload.title)
  end
end
