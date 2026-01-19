# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Molecule::Cards::PaddedImageComponentTest < Folio::ComponentTest
  def test_render
    atoms = [create_atom(Dummy::Atom::Cards::PaddedImage, :title, :cover, url_json: { href: "/" })]

    render_inline(Dummy::Molecule::Cards::PaddedImageComponent.new(atoms:))

    assert_selector(".d-molecule-cards-padded-image")
  end
end
