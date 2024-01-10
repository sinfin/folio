# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::DividerComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Divider)

    render_inline(Dummy::Atom::DividerComponent.new(atom:))

    assert_selector(".d-atom-divider")
  end
end
