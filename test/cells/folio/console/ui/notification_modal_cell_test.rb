# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::NotificationModalCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/ui/notification_modal", nil).(:show)
    assert html.has_css?(".f-c-ui-notification-modal")
  end
end
