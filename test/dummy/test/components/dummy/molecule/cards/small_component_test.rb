# frozen_string_literal: true

require "test_helper"

class Dummy::Molecule::Cards::SmallComponentTest < Folio::ComponentTest
  def test_render
    atoms = [create_atom(Dummy::Atom::Cards::Small, :content)]

    render_inline(Dummy::Molecule::Cards::SmallComponent.new(atoms:))

    assert_selector(".d-molecule-cards-small")
  end
end
