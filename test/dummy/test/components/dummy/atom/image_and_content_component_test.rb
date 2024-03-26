# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::ImageAndContentComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::ImageAndContent, :cover, :title)

    render_inline(Dummy::Atom::ImageAndContentComponent.new(atom:))

    assert_selector(".d-atom-image-and-content")
  end
end
