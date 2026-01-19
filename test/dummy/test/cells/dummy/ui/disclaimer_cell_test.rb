# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Ui::DisclaimerCellTest < Cell::TestCase
  test "show" do
    create_and_host_site

    html = cell("dummy/ui/disclaimer", nil).(:show)
    assert html.has_css?(".d-ui-disclaimer")
  end
end
