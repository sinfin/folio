# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::MarginCellTest < Cell::TestCase
  test "show" do
    atom = create_atom(Dummy::Atom::Margin)
    html = cell(atom.class.cell_name, atom).(:show)
    assert html
  end
end
