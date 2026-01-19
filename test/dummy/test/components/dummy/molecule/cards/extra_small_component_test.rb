# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Molecule::Cards::ExtraSmallComponentTest < Folio::ComponentTest
  def test_render
    atoms = [create_atom(Dummy::Atom::Cards::ExtraSmall, :title, url_json: { href: "/" })]

    render_inline(Dummy::Molecule::Cards::ExtraSmallComponent.new(atoms:))

    assert_selector(".d-molecule-cards-extra-small")
  end
end
