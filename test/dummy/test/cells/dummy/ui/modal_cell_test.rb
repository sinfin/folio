# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::ModalCellTest < Cell::TestCase
  test "show" do
    model = {
      class: "foo",
      body: "bar"
    }

    html = cell("dummy/ui/modal", model).(:show)
    assert html.has_css?(".d-ui-modal")
    assert html.has_css?(".foo")
    assert_equal "bar", html.text
  end
end
