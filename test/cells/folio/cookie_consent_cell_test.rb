# frozen_string_literal: true

require "test_helper"

class Folio::CookieConsentCellTest < Cell::TestCase
  test "show" do
    model = {
      create_url: "#",
      destroy_url: "#",
      index_url: "#",
      param_name: "#",
    }
    html = cell("folio/dropzone", model).(:show)
    assert html.has_css?(".f-dropzone")
  end
end
