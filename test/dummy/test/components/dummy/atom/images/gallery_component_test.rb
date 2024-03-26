# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::Images::GalleryComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Images::Gallery, :images)

    render_inline(Dummy::Atom::Images::GalleryComponent.new(atom:))

    assert_selector(".d-atom-images-gallery")
  end
end
