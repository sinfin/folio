# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Atom::Contents::DividerComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Contents::Divider)

    render_inline(Dummy::Atom::Contents::DividerComponent.new(atom:))

    assert_selector(".d-atom-contents-divider")
  end
end
