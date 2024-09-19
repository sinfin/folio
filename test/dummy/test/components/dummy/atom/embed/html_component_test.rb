# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::Embed::HtmlComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Embed::Html, :embed_code)

    render_inline(Dummy::Atom::Embed::HtmlComponent.new(atom:))

    assert_selector(".d-atom-embed-html")
  end
end
