# frozen_string_literal: true

require "test_helper"

class Dummy::Molecule::Cards::PaddedImageComponentTest < Folio::ComponentTest
  def test_render
    atoms = [create_atom(Dummy::Atom::Cards::PaddedImage, :title, :url, :cover)]

    render_inline(Dummy::Molecule::Cards::PaddedImageComponent.new(atoms:))

    assert_selector(".d-molecule-cards-padded-image")
  end
end
