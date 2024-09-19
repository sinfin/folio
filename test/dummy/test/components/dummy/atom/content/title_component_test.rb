# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::Content::TitleComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Content::Title, :title)

    render_inline(Dummy::Atom::Content::TitleComponent.new(atom:))

    assert_selector(".d-atom-content-title")
  end
end
