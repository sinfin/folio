# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::Content::DividerComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Content::Divider)

    render_inline(Dummy::Atom::Content::DividerComponent.new(atom:))

    assert_selector(".d-atom-content-divider")
  end
end
