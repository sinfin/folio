# frozen_string_literal: true

require "test_helper"

class Dummy::Molecule::DocumentsCellTest < Cell::TestCase
  test "show" do
    documents = create_list(:folio_document, 1)
    placement = create(:folio_page)

    atoms = Array.new(2) do
      create_atom(Dummy::Atom::Documents, documents:, placement:)
    end

    html = cell(atoms.first.class.molecule_cell_name, atoms).(:show)
    assert_equal 2, html.find_all(".d-molecule-documents__atom").size
  end
end
