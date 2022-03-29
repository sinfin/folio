# frozen_string_literal: true

require "test_helper"

class Dummy::Molecule::Blog::Articles::Card::LargeCellTest < Cell::TestCase
  test "show" do
    article = create(:dummy_blog_article)
    placement = create(:folio_page)

    atoms = Array.new(2) do
      create_atom(Dummy::Atom::Blog::Articles::Card::Large, article:, placement:)
    end

    html = cell(atoms.first.class.molecule_cell_name, atoms).(:show)
    assert_equal 2, html.find_all(".d-ui-article-card").size
  end
end
