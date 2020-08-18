# frozen_string_literal: true

require "test_helper"

class Folio::Atom::TitleCellTest < Cell::TestCase
  test "show" do
    atom = create_atom(Folio::Atom::Title, title: "foo")
    html = cell("folio/atom/title", atom).(:show)
    assert_equal "foo", html.find_css("h2").text
  end
end
