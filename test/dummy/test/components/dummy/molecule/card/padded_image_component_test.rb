# frozen_string_literal: true

require "test_helper"

class Dummy::Molecule::Card::PaddedImageComponentTest < Folio::ComponentTest
  def test_render
    atoms = [create_atom(Dummy::Atom::Card::PaddedImage, :title, :url, :cover)]

    render_inline(Dummy::Molecule::Card::PaddedImageComponent.new(atoms:))

    assert_selector(".d-molecule-card-padded-image")
  end
end
