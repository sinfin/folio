# frozen_string_literal: true

require "test_helper"

class Dummy::Molecule::Card::ImageComponentTest < Folio::ComponentTest
  def test_render
    atoms = [create_atom(Dummy::Atom::Card::Image, :title, :url, :cover)]

    render_inline(Dummy::Molecule::Card::ImageComponent.new(atoms:))

    assert_selector(".d-molecule-card-image")
  end
end
