# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::HeroComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Hero, :content)

    render_inline(Dummy::Atom::HeroComponent.new(atom:))

    assert_selector(".d-atom-hero")
  end
end
