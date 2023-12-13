# frozen_string_literal: true

require "test_helper"

class Dummy::Molecule::Card::LargeComponentTest < Folio::ComponentTest
  def test_render
    atoms = [create_atom(Dummy::Atom::Card::Large, :content)]

    render_inline(Dummy::Molecule::Card::LargeComponent.new(atoms:))

    assert_selector(".d-molecule-card-large")
  end
end
