# frozen_string_literal: true

require "test_helper"

class Folio::Console::SessionAttachments::ListCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/session_attachments/list", nil).(:show)
    assert_not html.has_css?(".f-c-session-attachments-list")

    img = create(:folio_session_attachment_image)
    html = cell("folio/console/session_attachments/list", [img]).(:show)
    assert html.has_css?(".f-c-session-attachments-list")
    assert html.has_css?(".f-c-file-list")

    doc = create(:folio_session_attachment_document)
    html = cell("folio/console/session_attachments/list", [img, doc]).(:show)
    assert html.has_css?(".f-c-session-attachments-list")
    assert_not html.has_css?(".f-c-file-list")
    assert html.has_css?(".f-c-file-table")
  end
end
