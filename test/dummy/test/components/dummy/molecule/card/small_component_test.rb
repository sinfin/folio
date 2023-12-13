# frozen_string_literal: true

require "test_helper"

class Dummy::Molecule::Card::SmallComponentTest < Folio::ComponentTest
  def test_render
    atoms = [create_atom(Dummy::Atom::Card::Small)]

    render_inline(Dummy::Molecule::Card::SmallComponent.new(atoms:))

    assert_selector(".d-molecule-card-small")
  end
end
