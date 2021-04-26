# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::TextTest < Cell::TestCase
  test "renders" do
    create(:folio_site)

    atom = create_atom(Dummy::Atom::Text, content: "<p>bar</p>")
    html = cell(atom.class.cell_name, atom).(:show)
    assert_equal("bar", html.find("p").text)
  end
end
