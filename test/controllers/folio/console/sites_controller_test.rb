# frozen_string_literal: true

require "test_helper"

class Folio::Console::SitesControllerTest < Folio::Console::BaseControllerTest
  test "edit" do
    get edit_console_site_path
    assert_response :ok
  end

  test "update" do
    assert_not_equal "foo", Folio::Site.instance.title
    put console_site_path, params: {
      site: {
        title: "foo",
      }
    }
    assert_equal "foo", Folio::Site.instance.title
  end
end
