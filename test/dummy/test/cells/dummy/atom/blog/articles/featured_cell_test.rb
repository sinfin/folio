# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::Blog::Articles::FeaturedCellTest < Cell::TestCase
  test "show" do
    atom = create_atom(Dummy::Atom::Blog::Articles::Featured)
    html = cell(atom.class.cell_name, atom).(:show)
    assert html

    create(:dummy_blog_article, featured: true)
    html = cell(atom.class.cell_name, atom).(:show)
    assert html
  end
end
