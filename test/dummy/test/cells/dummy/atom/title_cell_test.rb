# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::TitleCellTest < Cell::TestCase
  test "show" do
    atom = create_atom(Dummy::Atom::Title, :title)
    html = cell(atom.class.cell_name, atom).(:show)
    assert html
  end
end
