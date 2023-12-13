# frozen_string_literal: true

require "test_helper"

class Dummy::Molecule::Card::FullWidthComponentTest < Folio::ComponentTest
  def test_render
    atoms = [create_atom(Dummy::Atom::Card::FullWidth)]

    render_inline(Dummy::Molecule::Card::FullWidthComponent.new(atoms:))

    assert_selector(".d-molecule-card-full-width")
  end
end
