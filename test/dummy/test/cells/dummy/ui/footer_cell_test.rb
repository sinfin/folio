# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::FooterCellTest < Cell::TestCase
  test "show" do
    create(:folio_site)
    html = cell("dummy/ui/footer", nil).(:show)
    assert html.has_css?(".d-ui-footer")
  end
end
