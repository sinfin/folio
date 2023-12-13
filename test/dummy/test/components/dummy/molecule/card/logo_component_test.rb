# frozen_string_literal: true

require "test_helper"

class Dummy::Molecule::Card::LogoComponentTest < Folio::ComponentTest
  def test_render
    atoms = [create_atom(Dummy::Atom::Card::Logo, :cover)]

    render_inline(Dummy::Molecule::Card::LogoComponent.new(atoms:))

    assert_selector(".d-molecule-card-logo")
  end
end
