# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::Contents::TextWrappingImageComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Contents::TextWrappingImage, :cover, :content)

    render_inline(Dummy::Atom::Contents::TextWrappingImageComponent.new(atom:))

    assert_selector(".d-atom-contents-text-wrapping-image")
  end
end
