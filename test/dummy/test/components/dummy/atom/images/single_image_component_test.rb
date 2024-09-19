# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::Images::SingleImageComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Images::SingleImage, :cover)

    render_inline(Dummy::Atom::Images::SingleImageComponent.new(atom:))

    assert_selector(".d-atom-images-single-image")
  end
end
