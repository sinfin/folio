# frozen_string_literal: true

require "test_helper"

class Dummy::Molecule::Card::ExtraSmallComponentTest < Folio::ComponentTest
  def test_render
    atoms = [create_atom(Dummy::Atom::Card::ExtraSmall)]

    render_inline(Dummy::Molecule::Card::ExtraSmallComponent.new(atoms:))

    assert_selector(".d-molecule-card-extra-small")
  end
end
