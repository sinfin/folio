# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::Content::TextWrappingImageComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Content::TextWrappingImage, :cover, :content)

    render_inline(Dummy::Atom::Content::TextWrappingImageComponent.new(atom:))

    assert_selector(".d-atom-content-text-wrapping-image")
  end
end
