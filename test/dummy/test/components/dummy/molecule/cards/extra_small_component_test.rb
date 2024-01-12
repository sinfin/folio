# frozen_string_literal: true

require "test_helper"

class Dummy::Molecule::Cards::ExtraSmallComponentTest < Folio::ComponentTest
  def test_render
    atoms = [create_atom(Dummy::Atom::Cards::ExtraSmall)]

    render_inline(Dummy::Molecule::Cards::ExtraSmallComponent.new(atoms:))

    assert_selector(".d-molecule-cards-extra-small")
  end
end
