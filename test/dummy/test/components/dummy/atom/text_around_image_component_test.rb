# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::TextAroundImageComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::TextAroundImage, :cover, :content)

    render_inline(Dummy::Atom::TextAroundImageComponent.new(atom:))

    assert_selector(".d-atom-text-around-image")
  end
end
