# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::PerexComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Perex, :content)

    render_inline(Dummy::Atom::PerexComponent.new(atom:))

    assert_selector(".d-atom-perex")
  end
end
