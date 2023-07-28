# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::StiBadgeCellTest < Folio::Console::CellTest
  test "show" do
    page = create(:folio_page)

    html = cell("folio/console/ui/sti_badge", page).(:show)
    assert html.has_css?(".f-c-ui-sti-badge")

    html = cell("folio/console/ui/sti_badge", page, icon: :microphone).(:show)
    assert html.has_css?(".f-c-ui-sti-badge")
  end
end
