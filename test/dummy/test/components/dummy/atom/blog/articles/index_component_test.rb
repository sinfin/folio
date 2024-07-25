# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::Blog::Articles::IndexComponentTest < Folio::ComponentTest
  def test_render
    placement = create_page_singleton(Dummy::Page::Blog::Articles::Index)
    atom = create_atom(Dummy::Atom::Blog::Articles::Index, placement:)

    render_inline(Dummy::Atom::Blog::Articles::IndexComponent.new(atom:))

    assert_selector(".d-atom-blog-articles-index")
  end
end
