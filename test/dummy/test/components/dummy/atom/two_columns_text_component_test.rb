# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::TwoColumnsTextComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::TwoColumnsText, :title, :column_1, :column_2)

    render_inline(Dummy::Atom::TwoColumnsTextComponent.new(atom:))

    assert_selector(".d-atom-two-columns-text")
  end
end
