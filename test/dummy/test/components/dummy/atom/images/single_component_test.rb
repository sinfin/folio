# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::Images::SingleComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Images::Single, :cover)

    render_inline(Dummy::Atom::Images::SingleComponent.new(atom:))

    assert_selector(".d-atom-images-single")
  end
end
