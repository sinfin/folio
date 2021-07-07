# frozen_string_literal: true

require "test_helper"

class Dummy::Molecule::LogoCellTest < Cell::TestCase
  test "show" do
    cover = create(:folio_image)

    atoms = Array.new(2) do
      create_atom(Dummy::Atom::Logo, cover: cover)
    end

    html = cell(atoms.first.class.molecule_cell_name, atoms).(:show)
    assert_equal 2, html.find_all(".d-molecule-logo__atom").size
  end
end
