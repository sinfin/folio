# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::EmbedComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Embed, :embed_code)

    render_inline(Dummy::Atom::EmbedComponent.new(atom:))

    assert_selector(".d-atom-embed")
  end
end
