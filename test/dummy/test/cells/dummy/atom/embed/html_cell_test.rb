# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::Embed::HtmlCellTest < Cell::TestCase
  test "show" do
    atom = create_atom(Dummy::Atom::Embed::Html, :embed_code)
    html = cell(atom.class.cell_name, atom).(:show)
    assert html
  end
end
