# frozen_string_literal: true

require "test_helper"

class Folio::Console::Aasm::EmailModalCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/aasm/email_modal", nil).(:show)
    assert html.has_css?(".f-c-aasm-email-modal")
  end
end
