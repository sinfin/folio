# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::DocumentsComponentTest < Folio::ComponentTest
  def test_render
    document_placements = create_list(:folio_document_placement, 1)

    render_inline(Dummy::Ui::DocumentsComponent.new(document_placements:))

    assert_selector(".d-ui-documents")
  end
end
