# frozen_string_literal: true

require "test_helper"

class Dummy::Molecule::Cards::LogoComponentTest < Folio::ComponentTest
  def test_render
    atoms = [create_atom(Dummy::Atom::Cards::Logo, :cover)]

    render_inline(Dummy::Molecule::Cards::LogoComponent.new(atoms:))

    assert_selector(".d-molecule-cards-logo")
  end
end
