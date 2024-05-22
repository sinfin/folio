# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::ThreeColumnsTextComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::ThreeColumnsText, :title, :column_1, :column_2, :column_3)

    render_inline(Dummy::Atom::ThreeColumnsTextComponent.new(atom:))

    assert_selector(".d-atom-three-columns-text")
  end
end
