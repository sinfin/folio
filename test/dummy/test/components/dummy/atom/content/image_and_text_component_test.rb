# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::Content::ImageAndTextComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Content::ImageAndText, :cover, :title)

    render_inline(Dummy::Atom::Content::ImageAndTextComponent.new(atom:))

    assert_selector(".d-atom-content-image-and-text")
  end
end
