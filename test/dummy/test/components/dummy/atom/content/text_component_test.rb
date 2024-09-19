# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::Content::TextComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Content::Text, :content)

    render_inline(Dummy::Atom::Content::TextComponent.new(atom:))

    assert_selector(".d-atom-content-text")
  end
end
