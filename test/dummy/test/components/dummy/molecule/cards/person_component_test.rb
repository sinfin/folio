# frozen_string_literal: true

require "test_helper"

class Dummy::Molecule::Cards::PersonComponentTest < Folio::ComponentTest
  def test_render
    atoms = [create_atom(Dummy::Atom::Cards::Person, :name, :job)]

    render_inline(Dummy::Molecule::Cards::PersonComponent.new(atoms:))

    assert_selector(".d-molecule-cards-person")
  end
end
