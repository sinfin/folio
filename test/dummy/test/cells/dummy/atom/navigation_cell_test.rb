# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::NavigationCellTest < Cell::TestCase
  test "show" do
    atom = create_atom(Dummy::Atom::Navigation, menu: create(:dummy_menu))
    html = cell(atom.class.cell_name, atom).(:show)
    assert html
  end
end
