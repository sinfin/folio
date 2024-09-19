# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::Contents::LeadParagraphComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Contents::LeadParagraph, :content)

    render_inline(Dummy::Atom::Contents::LeadParagraphComponent.new(atom:))

    assert_selector(".d-atom-contents-lead-paragraph")
  end
end
