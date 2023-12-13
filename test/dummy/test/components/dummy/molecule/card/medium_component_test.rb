# frozen_string_literal: true

require "test_helper"

class Dummy::Molecule::Card::MediumComponentTest < Folio::ComponentTest
  def test_render
    atoms = [create_atom(Dummy::Atom::Card::Medium, :content)]

    render_inline(Dummy::Molecule::Card::MediumComponent.new(atoms:))

    assert_selector(".d-molecule-card-medium")
  end
end
