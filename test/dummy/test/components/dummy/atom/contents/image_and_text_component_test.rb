# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Atom::Contents::ImageAndTextComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Contents::ImageAndText, :cover, :title)

    render_inline(Dummy::Atom::Contents::ImageAndTextComponent.new(atom:))

    assert_selector(".d-atom-contents-image-and-text")
  end
end
