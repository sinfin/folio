# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Ui::DocumentsComponentTest < Folio::ComponentTest
  def test_render
    document_placements = create_list(:folio_file_placement_document, 1)

    render_inline(Dummy::Ui::DocumentsComponent.new(document_placements:))

    assert_selector(".d-ui-documents")
  end
end
