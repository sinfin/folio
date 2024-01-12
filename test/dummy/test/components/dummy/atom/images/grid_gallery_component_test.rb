# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::Images::GridGalleryComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Images::GridGallery, :images)

    render_inline(Dummy::Atom::Images::GridGalleryComponent.new(atom:))

    assert_selector(".d-atom-images-grid-gallery")
  end
end
