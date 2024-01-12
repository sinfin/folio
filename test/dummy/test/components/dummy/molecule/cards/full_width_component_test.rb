# frozen_string_literal: true

require "test_helper"

class Dummy::Molecule::Cards::FullWidthComponentTest < Folio::ComponentTest
  def test_render
    atoms = [create_atom(Dummy::Atom::Cards::FullWidth, :cover, :title)]

    render_inline(Dummy::Molecule::Cards::FullWidthComponent.new(atoms:))

    assert_selector(".d-molecule-cards-full-width")
  end
end
