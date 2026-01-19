# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Atom::Embeds::HtmlComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Embeds::Html, :embed_code)

    render_inline(Dummy::Atom::Embeds::HtmlComponent.new(atom:))

    assert_selector(".d-atom-embeds-html")
  end
end
