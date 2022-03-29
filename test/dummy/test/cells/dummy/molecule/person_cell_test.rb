# frozen_string_literal: true

require "test_helper"

class Dummy::Molecule::PersonCellTest < Cell::TestCase
  test "show" do
    placement = create(:folio_page)

    atoms = Array.new(2) do
      create_atom(Dummy::Atom::Person, :name, placement:)
    end

    html = cell(atoms.first.class.molecule_cell_name, atoms).(:show)
    assert_equal 2, html.find_all(".d-molecule-person__atom").size
  end
end
