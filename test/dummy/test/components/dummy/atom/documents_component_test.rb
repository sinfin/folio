# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::DocumentsComponentTest < Folio::ComponentTest
  def test_render
    document_placements = create_list(:folio_document_placement, 1)

    atom = create_atom(Dummy::Atom::Documents, document_placements:)

    render_inline(Dummy::Atom::DocumentsComponent.new(atom:))

    assert_selector(".d-atom-document")
  end
end
