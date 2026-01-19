# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Atom::Contents::TitleComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Contents::Title, :title)

    render_inline(Dummy::Atom::Contents::TitleComponent.new(atom:))

    assert_selector(".d-atom-contents-title")
  end
end
