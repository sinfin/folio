# frozen_string_literal: true

require "test_helper"

class Dummy::Molecule::Cards::ImageComponentTest < Folio::ComponentTest
  def test_render
    atoms = [create_atom(Dummy::Atom::Cards::Image, :title, :url, :cover)]

    render_inline(Dummy::Molecule::Cards::ImageComponent.new(atoms:))

    assert_selector(".d-molecule-cards-image")
  end
end
