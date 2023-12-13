# frozen_string_literal: true

require "test_helper"

class Dummy::Molecule::Card::PersonComponentTest < Folio::ComponentTest
  def test_render
    atoms = [create_atom(Dummy::Atom::Card::Person, :name, :job)]

    render_inline(Dummy::Molecule::Card::PersonComponent.new(atoms:))

    assert_selector(".d-molecule-card-person")
  end
end
