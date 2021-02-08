# frozen_string_literal: true

require "test_helper"

class Folio::Console::ContentTemplatesControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Folio::ContentTemplate])
    assert_response :success
  end

  test "edit" do
    get edit_console_content_templates_path(type: "Dummy::ContentTemplate::Title")
    assert_response :success
  end

  test "update" do
    assert_equal(0, Dummy::ContentTemplate::Title.count)
    patch update_console_content_templates_path(type: "Dummy::ContentTemplate::Title"), params: {
      content_template: {
        content_templates_attributes: {
          0 => {
            content: "foo",
          }
        }
      }
    }
    assert_redirected_to edit_console_content_templates_path(type: "Dummy::ContentTemplate::Title")
    assert_equal(1, Dummy::ContentTemplate::Title.count)
    assert_equal("foo", Dummy::ContentTemplate::Title.last.content)
  end
end
