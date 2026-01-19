# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Molecule::Cards::ImageComponentTest < Folio::ComponentTest
  def test_render
    atoms = [create_atom(Dummy::Atom::Cards::Image, :title, :cover, url_json: { href: "/foo" })]

    render_inline(Dummy::Molecule::Cards::ImageComponent.new(atoms:))

    assert_selector(".d-molecule-cards-image")
  end
end
