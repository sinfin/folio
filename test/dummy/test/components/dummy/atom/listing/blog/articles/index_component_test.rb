# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::Listing::Blog::Articles::IndexComponentTest < Folio::ComponentTest
  def test_render
    create_and_host_site
    placement = create_page_singleton(Dummy::Page::Blog::Articles::Index)
    atom = create_atom(Dummy::Atom::Listing::Blog::Articles::Index, placement:)

    render_inline(Dummy::Atom::Listing::Blog::Articles::IndexComponent.new(atom:))

    assert_selector(".d-atom-listing-blog-articles-index")
  end
end
