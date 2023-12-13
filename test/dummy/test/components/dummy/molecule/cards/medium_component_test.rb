# frozen_string_literal: true

require "test_helper"

class Dummy::Molecule::Cards::MediumComponentTest < Folio::ComponentTest
  def test_render
    atoms = [create_atom(Dummy::Atom::Cards::Medium, :content)]

    render_inline(Dummy::Molecule::Cards::MediumComponent.new(atoms:))

    assert_selector(".d-molecule-cards-medium")
  end
end
