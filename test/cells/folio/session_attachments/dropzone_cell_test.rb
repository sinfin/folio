# frozen_string_literal: true

require "test_helper"

class Folio::SessionAttachments::DropzoneCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/session_attachments/dropzone",
                Dummy::SessionAttachment::Image).(:show)
    assert html.has_css?(".f-session-attachments-dropzone")
  end
end
