# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::MapCellTest < Cell::TestCase
  test "show" do
    atom = create_atom(Dummy::Atom::Map, latlng: "50.091254894762635, 14.401627227698018")
    html = cell(atom.class.cell_name, atom).(:show)
    assert html
  end
end
