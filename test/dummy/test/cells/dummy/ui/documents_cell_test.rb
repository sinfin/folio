# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::DocumentsCellTest < Cell::TestCase
  test "show" do
    document_placements = create_list(:folio_document_placement, 1)
    html = cell("dummy/ui/documents", document_placements).(:show)
    assert html.has_css?(".d-ui-documents")

    html = cell("dummy/ui/documents", document_placements, title: "foo").(:show)
    assert html.has_css?(".d-ui-documents")
  end
end
