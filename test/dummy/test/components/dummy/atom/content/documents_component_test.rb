# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::Content::DocumentsComponentTest < Folio::ComponentTest
  def test_render
    document_placements = create_list(:folio_document_placement, 1)

    atom = create_atom(Dummy::Atom::Content::Documents, document_placements:)

    render_inline(Dummy::Atom::Content::DocumentsComponent.new(atom:))

    assert_selector(".d-atom-content-documents")
  end
end
