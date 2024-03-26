# frozen_string_literal: true

require "test_helper"

class Dummy::Molecule::Cards::LargeComponentTest < Folio::ComponentTest
  def test_render
    atoms = [create_atom(Dummy::Atom::Cards::Large, :content)]

    render_inline(Dummy::Molecule::Cards::LargeComponent.new(atoms:))

    assert_selector(".d-molecule-cards-large")
  end
end
