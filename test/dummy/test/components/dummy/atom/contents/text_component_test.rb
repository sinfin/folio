# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Atom::Contents::TextComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Contents::Text, :content)

    render_inline(Dummy::Atom::Contents::TextComponent.new(atom:))

    assert_selector(".d-atom-contents-text")
  end
end
