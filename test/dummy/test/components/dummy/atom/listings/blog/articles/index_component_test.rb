# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Atom::Listings::Blog::Articles::IndexComponentTest < Folio::ComponentTest
  def test_render
    create_and_host_site
    placement = create_page_singleton(Dummy::Page::Blog::Articles::Index)
    atom = create_atom(Dummy::Atom::Listings::Blog::Articles::Index, placement:)

    render_inline(Dummy::Atom::Listings::Blog::Articles::IndexComponent.new(atom:))

    assert_selector(".d-atom-listings-blog-articles-index")
  end
end
