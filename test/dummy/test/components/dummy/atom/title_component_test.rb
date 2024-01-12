# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::TitleComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Title, :title)

    render_inline(Dummy::Atom::TitleComponent.new(atom:))

    assert_selector(".d-atom-title")
  end
end
