# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::PerexCellTest < Cell::TestCase
  test "show" do
    atom = create_atom(Dummy::Atom::Perex, :text)
    html = cell(atom.class.cell_name, atom).(:show)
    assert html
  end
end
