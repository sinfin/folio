# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Atom::Contents::DocumentsComponentTest < Folio::ComponentTest
  def test_render
    document_placements = create_list(:folio_file_placement_document, 1)

    atom = create_atom(Dummy::Atom::Contents::Documents, document_placements:)

    render_inline(Dummy::Atom::Contents::DocumentsComponent.new(atom:))

    assert_selector(".d-atom-contents-documents")
  end
end
