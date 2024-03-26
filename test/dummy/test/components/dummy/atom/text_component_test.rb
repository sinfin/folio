# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::TextComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Text, :content)

    render_inline(Dummy::Atom::TextComponent.new(atom:))

    assert_selector(".d-atom-text")
  end
end
