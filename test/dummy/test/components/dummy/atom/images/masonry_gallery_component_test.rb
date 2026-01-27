# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Atom::Images::MasonryGalleryComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Images::MasonryGallery, :images)

    render_inline(Dummy::Atom::Images::MasonryGalleryComponent.new(atom:))

    assert_selector(".d-atom-images-masonry-gallery")
  end
end
